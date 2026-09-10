import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";
import { Message } from "firebase-admin/messaging";
import * as crypto from "crypto";

import { smsProviderSecret, twilioAccountSidSecret, twilioAuthTokenSecret, twilioFromNumberSecret, CONFIG } from "./config";
import { FcmService } from "./services/fcm_service";
import { SmsService } from "./services/sms_service";
import { DeliveryService } from "./services/delivery_service";
import { NotificationService } from "./services/notification_service";
import { safeLogger } from "./utils/logger";
import { generateIdempotencyKey } from "./utils/idempotency";
import { redactFcmToken, redactPhoneNumber } from "./utils/redaction";
import { EmergencyContact } from "./types";

initializeApp();

const db = getFirestore();
const auth = getAuth();
const fcmService = new FcmService();
const smsService = new SmsService();
const deliveryService = new DeliveryService();
const notificationService = new NotificationService();

function generateOpaqueToken(): string {
  return crypto.randomBytes(32).toString("hex");
}

function hashToken(token: string): string {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function generateDisplayEmergencyId(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let part1 = "";
  let part2 = "";
  for (let i = 0; i < 4; i++) {
    part1 += chars.charAt(Math.floor(Math.random() * chars.length));
    part2 += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return `ST-${part1}-${part2}`;
}

// -----------------------------------------------------------------------------
// PUBLIC & USER QR ENDPOINTS (PHASE 5)
// -----------------------------------------------------------------------------

export const resolveEmergencyQr = onCall(async (request) => {
  const inputToken = request.data?.token || request.data?.qrPayload;
  const sourceType = request.data?.sourceType || "camera";

  if (!inputToken || typeof inputToken !== "string") {
    throw new HttpsError("invalid-argument", "invalid_token");
  }

  let rawToken = inputToken.trim();
  if (rawToken.includes("/qr/")) {
    const parts = rawToken.split("/qr/");
    rawToken = parts[parts.length - 1];
  }

  if (rawToken.length < 16) {
    throw new HttpsError("invalid-argument", "invalid_token");
  }

  const tokenHash = hashToken(rawToken);
  safeLogger.info(`Attempting public emergency QR resolution via token hash lookup.`);

  try {
    const tokenQuery = await db
      .collection("emergency_qr_tokens")
      .where("tokenHash", "==", tokenHash)
      .limit(1)
      .get();

    if (tokenQuery.empty) {
      safeLogger.warn(`Public QR resolve failed: No token matching hash found.`);
      throw new HttpsError("not-found", "invalid_token");
    }

    const tokenDoc = tokenQuery.docs[0];
    const tokenData = tokenDoc.data();

    if (tokenData.status === "revoked") {
      safeLogger.warn(`Public QR resolve rejected: Token ${tokenDoc.id} is revoked.`);
      throw new HttpsError("failed-precondition", "revoked_token");
    }

    if (tokenData.status !== "active") {
      throw new HttpsError("failed-precondition", "invalid_token");
    }

    const now = new Date();
    if (tokenData.expiresAt && tokenData.expiresAt.toDate() < now) {
      safeLogger.warn(`Public QR resolve rejected: Token ${tokenDoc.id} expired at ${tokenData.expiresAt.toDate()}`);
      throw new HttpsError("failed-precondition", "expired_token");
    }

    const ownerUserId = tokenData.ownerUserId;
    const profileDoc = await db.collection("medical_profiles").doc(ownerUserId).get();
    if (!profileDoc.exists) {
      safeLogger.warn(`Medical profile for owner ${ownerUserId} not found.`);
      throw new HttpsError("not-found", "unavailable");
    }

    const profile = profileDoc.data() || {};

    // Authoritative check: if emergencyAccessEnabled is false, return safe disabled response
    if (profile.emergencyAccessEnabled === false) {
      safeLogger.warn(`Emergency access disabled by profile owner ${ownerUserId}`);
      throw new HttpsError("permission-denied", "unavailable");
    }

    let emergencyContacts: Array<any> = [];
    if (profile.shareEmergencyContactsInEmergency !== false && profile.shareContactsInEmergency !== false) {
      const contactsSnapshot = await db
        .collection("users")
        .doc(ownerUserId)
        .collection("emergency_contacts")
        .orderBy("priority", "asc")
        .limit(5)
        .get();

      emergencyContacts = contactsSnapshot.docs.map((cDoc) => {
        const cData = cDoc.data();
        return {
          id: cDoc.id,
          name: cData.name,
          relationship: cData.relationship,
          phoneNumber: cData.phoneNumber,
        };
      });
    }

    await tokenDoc.ref.update({
      scanCount: FieldValue.increment(1),
      lastScannedAt: FieldValue.serverTimestamp(),
    });

    const auditRef = db.collection("qr_scan_audits").doc();
    await auditRef.set({
      auditId: auditRef.id,
      tokenId: tokenDoc.id,
      ownerUserId: ownerUserId,
      scannedAt: FieldValue.serverTimestamp(),
      sourceType: sourceType,
    });

    const redactedDto = {
      displayEmergencyId: tokenData.displayEmergencyId,
      fullName: profile.shareNameInEmergency !== false ? profile.fullName : "Emergency Patient",
      photoUrl: profile.sharePhotoInEmergency === true ? profile.photoUrl : null,
      bloodGroup: profile.shareBloodGroupInEmergency !== false ? (profile.bloodGroup || "Not Specified") : "Restricted",
      allergies: profile.shareAllergiesInEmergency !== false ? (profile.allergies || "None reported") : "Restricted",
      medicalConditions: profile.shareMedicalConditionsInEmergency !== false ? (profile.medicalConditions || "None reported") : "Restricted",
      currentMedications: profile.shareMedicationsInEmergency !== false ? (profile.currentMedications || "None reported") : "Restricted",
      implants: profile.shareImplantsInEmergency !== false ? (profile.implants || "None reported") : "Restricted",
      emergencyNotes: profile.shareEmergencyNotesInEmergency !== false ? (profile.notes || "") : "Restricted",
      primaryDoctor: profile.shareDoctorHospitalInEmergency !== false ? profile.primaryDoctor : null,
      preferredHospital: profile.shareDoctorHospitalInEmergency !== false ? profile.preferredHospital : null,
      hospitalAddress:
        profile.shareDoctorHospitalInEmergency !== false && profile.shareHospitalDirectionsInEmergency !== false
          ? profile.hospitalAddress
          : null,
      emergencyContacts: emergencyContacts,
      lastUpdated: profile.lastEmergencyProfileUpdateAt
        ? profile.lastEmergencyProfileUpdateAt.toDate().toISOString()
        : null,
    };

    safeLogger.info(`Successfully resolved Emergency QR for ID ${tokenData.displayEmergencyId}`);
    return redactedDto;
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    safeLogger.error("Error resolving emergency QR code", error);
    throw new HttpsError("internal", "unavailable");
  }
});

export const createEmergencyQr = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const userId = request.auth.uid;
  try {
    const existingTokens = await db
      .collection("emergency_qr_tokens")
      .where("ownerUserId", "==", userId)
      .where("status", "==", "active")
      .get();

    const batch = db.batch();
    existingTokens.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: "revoked",
        revokedAt: FieldValue.serverTimestamp(),
      });
    });

    const rawToken = generateOpaqueToken();
    const tokenHash = hashToken(rawToken);
    const displayEmergencyId = generateDisplayEmergencyId();

    const tokenRef = db.collection("emergency_qr_tokens").doc();
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);

    const tokenData = {
      tokenId: tokenRef.id,
      ownerUserId: userId,
      tokenHash: tokenHash,
      status: "active",
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromDate(expiresAt),
      revokedAt: null,
      lastScannedAt: null,
      scanCount: 0,
      allowedFieldsVersion: 1,
      emergencyProfileVersion: 1,
      displayEmergencyId: displayEmergencyId,
      notificationOnScan: true,
      lastScanMetadata: null,
    };

    batch.set(tokenRef, tokenData);
    await batch.commit();

    return {
      tokenId: tokenRef.id,
      rawPayload: `https://vitanexus.web.app/qr/${rawToken}`,
      rawToken: rawToken,
      displayEmergencyId: displayEmergencyId,
      expiresAt: expiresAt.toISOString(),
    };
  } catch (error) {
    throw new HttpsError("internal", "Failed to generate emergency QR code.");
  }
});

export const revokeEmergencyQr = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const userId = request.auth.uid;
  const tokenId = request.data?.tokenId;

  if (!tokenId || typeof tokenId !== "string") {
    throw new HttpsError("invalid-argument", "Valid tokenId required.");
  }

  try {
    const tokenDoc = await db.collection("emergency_qr_tokens").doc(tokenId).get();
    if (!tokenDoc.exists || tokenDoc.data()?.ownerUserId !== userId) {
      throw new HttpsError("permission-denied", "Unauthorized.");
    }

    await tokenDoc.ref.update({
      status: "revoked",
      revokedAt: FieldValue.serverTimestamp(),
    });

    return { success: true, tokenId: tokenId };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to revoke emergency QR code.");
  }
});

export const regenerateEmergencyQr = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  return await createEmergencyQr.run(request);
});

export const getEmergencyQrMetadata = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const userId = request.auth.uid;

  try {
    const snapshot = await db
      .collection("emergency_qr_tokens")
      .where("ownerUserId", "==", userId)
      .where("status", "==", "active")
      .limit(1)
      .get();

    if (snapshot.empty) {
      return { active: false, metadata: null };
    }

    const doc = snapshot.docs[0];
    const data = doc.data();

    return {
      active: true,
      metadata: {
        tokenId: data.tokenId,
        status: data.status,
        displayEmergencyId: data.displayEmergencyId,
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
        expiresAt: data.expiresAt ? data.expiresAt.toDate().toISOString() : null,
        scanCount: data.scanCount || 0,
        lastScannedAt: data.lastScannedAt ? data.lastScannedAt.toDate().toISOString() : null,
        notificationOnScan: data.notificationOnScan ?? true,
      },
    };
  } catch (error) {
    throw new HttpsError("internal", "Failed to fetch QR metadata.");
  }
});

// -----------------------------------------------------------------------------
// PROTECTED ACCOUNT DELETION CALLABLE FUNCTION (PHASE 7)
// -----------------------------------------------------------------------------

export const deleteUserAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const userId = request.auth.uid;
  safeLogger.info(`Initiating account deletion for user ${userId}`);

  try {
    // 1. Revoke and delete owner QR tokens
    const qrTokensSnapshot = await db
      .collection("emergency_qr_tokens")
      .where("ownerUserId", "==", userId)
      .get();

    const batch = db.batch();
    qrTokensSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    // 2. Delete medical profile
    batch.delete(db.collection("medical_profiles").doc(userId));

    // 3. Delete emergency contacts subcollection
    const contactsSnapshot = await db
      .collection("users")
      .doc(userId)
      .collection("emergency_contacts")
      .get();
    contactsSnapshot.docs.forEach((doc) => batch.delete(doc.ref));

    // 4. Delete device tokens subcollection
    const tokensSnapshot = await db
      .collection("users")
      .doc(userId)
      .collection("device_tokens")
      .get();
    tokensSnapshot.docs.forEach((doc) => batch.delete(doc.ref));

    // 5. Delete notification preferences
    const prefRef = db.collection("users").doc(userId).collection("notification_preferences").doc("settings");
    batch.delete(prefRef);

    // 6. Delete privacy settings
    const privacyRef = db.collection("users").doc(userId).collection("privacy_settings").doc("settings");
    batch.delete(privacyRef);

    // 7. Delete user root document
    batch.delete(db.collection("users").doc(userId));

    await batch.commit();

    // 8. Delete user storage files if present
    try {
      const bucket = getStorage().bucket();
      await bucket.deleteFiles({ prefix: `users/${userId}/` });
    } catch (_) {
      // Ignore if storage files don't exist
    }

    // 9. Delete Firebase Auth user
    await auth.deleteUser(userId);

    safeLogger.info(`Successfully completed account deletion for user ${userId}`);
    return { success: true };
  } catch (error) {
    safeLogger.error(`Error deleting account for user ${userId}`, error);
    throw new HttpsError("internal", "Failed to delete account completely.");
  }
});

// -----------------------------------------------------------------------------
// FIRESTORE TRIGGERS FOR SECURE SOS DISPATCH & NOTIFICATIONS (PHASE 6)
// -----------------------------------------------------------------------------

export const onEmergencyAlertCreated = onDocumentCreated(
  {
    document: "emergency_alerts/{alertId}",
    secrets: [smsProviderSecret, twilioAccountSidSecret, twilioAuthTokenSecret, twilioFromNumberSecret],
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const alertData = snapshot.data();
    const alertId = event.params.alertId;
    const ownerUserId = alertData?.ownerUserId;

    if (!alertData || alertData.status !== "active" || !ownerUserId) {
      safeLogger.info(`Ignoring alert creation ${alertId}: Invalid status or missing ownerUserId.`);
      return;
    }

    if (alertData.notificationStatus === "dispatched") {
      safeLogger.info(`Alert ${alertId} already dispatched. Skipping.`);
      return;
    }

    safeLogger.info(`Processing emergency alert dispatch for alertId=${alertId}`);

    try {
      const contactsSnapshot = await db
        .collection("users")
        .doc(ownerUserId)
        .collection("emergency_contacts")
        .get();

      if (contactsSnapshot.empty) {
        safeLogger.info(`No emergency contacts found for ownerUserId=${ownerUserId}`);
        await snapshot.ref.update({ notificationStatus: "no_recipients" });
        return;
      }

      const fcmPayloads: Array<{ message: Message; ownerUserId: string; tokenId: string; contactId: string; recipientUserId: string; idempotencyKey: string }> = [];

      for (const contactDoc of contactsSnapshot.docs) {
        const contact = contactDoc.data() as EmergencyContact;
        const contactId = contactDoc.id;

        if (contact.recipientUserId && contact.allowPushNotifications !== false) {
          const recipientId = contact.recipientUserId;

          const prefDoc = await db
            .collection("users")
            .doc(recipientId)
            .collection("notification_preferences")
            .doc("settings")
            .get();

          const prefData = prefDoc.data();
          const isPushEnabled = prefData?.sosPushEnabled !== false;

          if (isPushEnabled) {
            const idempotencyKey = generateIdempotencyKey(alertId, recipientId, "fcm", "create");
            const alreadyProcessed = await deliveryService.isIdempotencyKeyProcessed(idempotencyKey);

            if (!alreadyProcessed) {
              const tokensSnapshot = await db
                .collection("users")
                .doc(recipientId)
                .collection("device_tokens")
                .where("enabled", "==", true)
                .get();

              for (const tokenDoc of tokensSnapshot.docs) {
                const tokenData = tokenDoc.data();
                const fcmToken = tokenData.token;

                if (fcmToken) {
                  fcmPayloads.push({
                    message: {
                      token: fcmToken,
                      notification: {
                        title: CONFIG.DEFAULT_NOTIFICATION_TITLE,
                        body: CONFIG.DEFAULT_NOTIFICATION_BODY,
                      },
                      data: {
                        type: "sos_alert",
                        alertId: alertId,
                        route: `/sos-alert/${alertId}`,
                      },
                      android: {
                        priority: "high",
                        notification: {
                          sound: "default",
                          channelId: "emergency_sos_channel",
                        },
                      },
                      apns: {
                        payload: {
                          aps: {
                            sound: "default",
                            badge: 1,
                          },
                        },
                      },
                    },
                    ownerUserId: recipientId,
                    tokenId: tokenDoc.id,
                    contactId: contactId,
                    recipientUserId: recipientId,
                    idempotencyKey: idempotencyKey,
                  });
                }
              }

              await notificationService.createNotification({
                recipientUserId: recipientId,
                senderUserId: ownerUserId,
                title: CONFIG.DEFAULT_NOTIFICATION_TITLE,
                body: CONFIG.DEFAULT_NOTIFICATION_BODY,
                type: "sos_alert",
                alertId: alertId,
              });
            }
          } else {
            safeLogger.info(`Push notifications disabled by recipient ${recipientId}`);
          }
        }

        if (contact.allowSmsNotifications === true && contact.smsConsentAt && contact.phoneNumber) {
          const smsIdempotencyKey = generateIdempotencyKey(alertId, contactId, "sms", "create");
          const alreadyProcessed = await deliveryService.isIdempotencyKeyProcessed(smsIdempotencyKey);

          if (!alreadyProcessed) {
            const smsResult = await smsService.sendEmergencySms(contact.phoneNumber);

            await deliveryService.recordDelivery({
              alertId: alertId,
              recipientUserId: contact.recipientUserId || null,
              recipientContactId: contactId,
              channel: "sms",
              status: smsResult.status,
              providerMessageId: smsResult.providerMessageId,
              failureCode: smsResult.failureCode,
              failureReason: smsResult.failureReason,
              idempotencyKey: smsIdempotencyKey,
            });
          }
        }
      }

      if (fcmPayloads.length > 0) {
        const { successCount, failureCount } = await fcmService.sendMessages(fcmPayloads);

        for (const payload of fcmPayloads) {
          await deliveryService.recordDelivery({
            alertId: alertId,
            recipientUserId: payload.recipientUserId,
            recipientContactId: payload.contactId,
            channel: "fcm",
            status: successCount > 0 ? "sent" : "failed",
            idempotencyKey: payload.idempotencyKey,
          });
        }

        safeLogger.info(`FCM Dispatch completed for alert ${alertId}. Sent=${successCount}, Failed=${failureCount}`);
      }

      await snapshot.ref.update({
        notificationStatus: "dispatched",
        dispatchedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      safeLogger.error(`Error executing alert creation trigger for ${alertId}`, error);
      await snapshot.ref.update({ notificationStatus: "failed" });
    }
  }
);

export const onEmergencyAlertUpdated = onDocumentUpdated(
  "emergency_alerts/{alertId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    if (!beforeData || !afterData) return;

    const alertId = event.params.alertId;

    if (beforeData.status === "active" && (afterData.status === "resolved" || afterData.status === "cancelled")) {
      const ownerUserId = afterData.ownerUserId;
      safeLogger.info(`SOS alert ${alertId} transitioned from active to ${afterData.status}. Dispatching resolution notifications.`);

      try {
        const contactsSnapshot = await db
          .collection("users")
          .doc(ownerUserId)
          .collection("emergency_contacts")
          .get();

        for (const doc of contactsSnapshot.docs) {
          const contact = doc.data() as EmergencyContact;

          if (contact.recipientUserId) {
            const recipientId = contact.recipientUserId;
            const idempotencyKey = generateIdempotencyKey(alertId, recipientId, "fcm", "resolve");

            const alreadyProcessed = await deliveryService.isIdempotencyKeyProcessed(idempotencyKey);
            if (alreadyProcessed) continue;

            await notificationService.createNotification({
              recipientUserId: recipientId,
              senderUserId: ownerUserId,
              title: CONFIG.RESOLVED_NOTIFICATION_TITLE,
              body: CONFIG.RESOLVED_NOTIFICATION_BODY,
              type: "sos_resolved",
              alertId: alertId,
            });

            const tokensSnapshot = await db
              .collection("users")
              .doc(recipientId)
              .collection("device_tokens")
              .where("enabled", "==", true)
              .get();

            const resFcmPayloads = tokensSnapshot.docs
              .map((tDoc) => tDoc.data().token)
              .filter(Boolean)
              .map((token) => ({
                message: {
                  token: token,
                  notification: {
                    title: CONFIG.RESOLVED_NOTIFICATION_TITLE,
                    body: CONFIG.RESOLVED_NOTIFICATION_BODY,
                  },
                  data: {
                    type: "sos_resolved",
                    alertId: alertId,
                    route: `/sos-alert/${alertId}`,
                  },
                },
                ownerUserId: recipientId,
                tokenId: token,
              }));

            if (resFcmPayloads.length > 0) {
              await fcmService.sendMessages(resFcmPayloads);
            }

            await deliveryService.recordDelivery({
              alertId: alertId,
              recipientUserId: recipientId,
              recipientContactId: doc.id,
              channel: "fcm",
              status: "sent",
              idempotencyKey: idempotencyKey,
            });
          }
        }
      } catch (error) {
        safeLogger.error(`Error sending resolution notification for alert ${alertId}`, error);
      }
    }
  }
);

// -----------------------------------------------------------------------------
// IOT DEVICE PAIRING & EVENT INGESTION CALLABLE / REST ENDPOINTS (PHASE 9.3)
// -----------------------------------------------------------------------------

export const createDevicePairingSession = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const userId = request.auth.uid;
  const deviceType = request.data?.deviceType || "ble_wearable";

  try {
    const sessionId = `pair_${generateOpaqueToken().substring(0, 16)}`;
    const challengeCode = Math.floor(100000 + Math.random() * 900000).toString();
    const challengeHash = hashToken(challengeCode);
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 mins

    const sessionRef = db.collection("device_pairing_sessions").doc(sessionId);
    await sessionRef.set({
      sessionId: sessionId,
      ownerUserId: userId,
      deviceType: deviceType,
      status: "pending",
      challengeHash: challengeHash,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromDate(expiresAt),
      pairedDeviceId: null,
    });

    safeLogger.info(`Created device pairing session ${sessionId} for user ${userId}`);
    return {
      sessionId: sessionId,
      challengeCode: challengeCode,
      expiresAt: expiresAt.toISOString(),
    };
  } catch (error) {
    safeLogger.error("Error creating device pairing session", error);
    throw new HttpsError("internal", "Failed to create pairing session.");
  }
});

export const completeDevicePairing = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const userId = request.auth.uid;
  const sessionId = request.data?.sessionId;
  const challengeCode = request.data?.challengeCode;
  const deviceName = request.data?.displayName || "SOZOTAP Hardware Device";
  const connectionType = request.data?.connectionType || "wifi";

  if (!sessionId || !challengeCode) {
    throw new HttpsError("invalid-argument", "sessionId and challengeCode are required.");
  }

  try {
    const sessionDoc = await db.collection("device_pairing_sessions").doc(sessionId).get();
    if (!sessionDoc.exists || sessionDoc.data()?.ownerUserId !== userId) {
      throw new HttpsError("permission-denied", "Unauthorized pairing attempt.");
    }

    const sData = sessionDoc.data()!;
    if (sData.status !== "pending") {
      throw new HttpsError("failed-precondition", "Pairing session is no longer pending.");
    }

    if (sData.expiresAt.toDate() < new Date()) {
      throw new HttpsError("failed-precondition", "Pairing session expired.");
    }

    if (hashToken(challengeCode) !== sData.challengeHash) {
      throw new HttpsError("invalid-argument", "Invalid challenge code.");
    }

    const deviceId = `dev_${generateOpaqueToken().substring(0, 16)}`;
    const secretToken = generateOpaqueToken();

    const deviceRef = db.collection("iot_devices").doc(deviceId);
    const now = new Date();

    const deviceData = {
      deviceId: deviceId,
      ownerUserId: userId,
      displayName: deviceName,
      connectionType: connectionType,
      status: "paired",
      firmwareVersion: "1.0.0",
      batteryLevel: 100,
      lastSeenAt: FieldValue.serverTimestamp(),
      pairedAt: FieldValue.serverTimestamp(),
      revokedAt: null,
      sosEnabled: true,
      deviceLocationEnabled: true,
      secretTokenHash: hashToken(secretToken),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    const batch = db.batch();
    batch.set(deviceRef, deviceData);
    batch.update(sessionDoc.ref, {
      status: "paired",
      pairedDeviceId: deviceId,
      pairedAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();

    safeLogger.info(`Successfully completed pairing for device ${deviceId}`);
    return {
      deviceId: deviceId,
      secretToken: secretToken,
      pairedAt: now.toISOString(),
    };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    safeLogger.error("Error completing device pairing", error);
    throw new HttpsError("internal", "Failed to complete device pairing.");
  }
});

export const revokeDevice = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const userId = request.auth.uid;
  const deviceId = request.data?.deviceId;

  if (!deviceId) throw new HttpsError("invalid-argument", "deviceId required.");

  try {
    const devDoc = await db.collection("iot_devices").doc(deviceId).get();
    if (!devDoc.exists || devDoc.data()?.ownerUserId !== userId) {
      throw new HttpsError("permission-denied", "Unauthorized.");
    }

    await devDoc.ref.update({
      status: "revoked",
      revokedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { success: true, deviceId: deviceId };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to revoke device.");
  }
});

export const ingestDeviceEvent = onCall(async (request) => {
  const { deviceId, secretToken, eventId, eventType, batteryLevel, payload } = request.data || {};

  if (!deviceId || !secretToken || !eventId || !eventType) {
    throw new HttpsError("invalid-argument", "Missing required fields.");
  }

  try {
    const devDoc = await db.collection("iot_devices").doc(deviceId).get();
    if (!devDoc.exists) {
      throw new HttpsError("not-found", "Device not registered.");
    }

    const devData = devDoc.data()!;
    if (devData.status !== "paired" || devData.secretTokenHash !== hashToken(secretToken)) {
      throw new HttpsError("permission-denied", "Invalid device credentials.");
    }

    const ownerUserId = devData.ownerUserId;
    const idempotencyKey = `${deviceId}-${eventId}`;

    // Duplicate check
    const existingEvt = await db.collection("device_events").doc(eventId).get();
    if (existingEvt.exists) {
      return { status: "ignored", reason: "duplicate_event" };
    }

    const eventRef = db.collection("device_events").doc(eventId);
    await eventRef.set({
      eventId: eventId,
      deviceId: deviceId,
      ownerUserId: ownerUserId,
      type: eventType,
      createdAt: FieldValue.serverTimestamp(),
      status: "received",
      batteryLevel: batteryLevel || null,
      payload: payload || {},
      idempotencyKey: idempotencyKey,
    });

    // Update battery & lastSeenAt on device
    await devDoc.ref.update({
      lastSeenAt: FieldValue.serverTimestamp(),
      batteryLevel: batteryLevel || devData.batteryLevel,
    });

    // If SOS event, create emergency_alert to trigger FCM/SMS pipeline
    if (eventType === "sos_pressed" || eventType === "fall_candidate") {
      const alertRef = db.collection("emergency_alerts").doc();
      await alertRef.set({
        alertId: alertRef.id,
        ownerUserId: ownerUserId,
        status: "active",
        createdAt: FieldValue.serverTimestamp(),
        source: `iot_${deviceId}`,
        deviceType: devData.connectionType,
      });
      safeLogger.info(`Triggered emergency alert ${alertRef.id} via IoT event ${eventId}`);
    }

    return { status: "processed", eventId: eventId };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    safeLogger.error("Error ingesting device event", error);
    throw new HttpsError("internal", "Failed to ingest device event.");
  }
});

// -----------------------------------------------------------------------------
// CAREGIVER ACCESS CALLABLE FUNCTIONS (PHASE 9.4)
// -----------------------------------------------------------------------------

export const createCaregiverInvitation = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const ownerUserId = request.auth.uid;
  const caregiverEmail = request.data?.caregiverEmail;
  const permissions = request.data?.permissions || {
    viewEmergencySummary: true,
    receiveSosAlerts: true,
    viewActiveSosLocation: true,
  };

  if (!caregiverEmail || typeof caregiverEmail !== "string") {
    throw new HttpsError("invalid-argument", "caregiverEmail required.");
  }

  try {
    const userRecord = await auth.getUserByEmail(caregiverEmail.trim());
    const caregiverUserId = userRecord.uid;

    if (caregiverUserId === ownerUserId) {
      throw new HttpsError("invalid-argument", "Cannot invite yourself as caregiver.");
    }

    const relId = `rel_${ownerUserId}_${caregiverUserId}`;
    const relRef = db.collection("caregiver_relationships").doc(relId);

    await relRef.set({
      relationshipId: relId,
      ownerUserId: ownerUserId,
      caregiverUserId: caregiverUserId,
      role: "Caregiver",
      permissions: permissions,
      invitationStatus: "pending",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    safeLogger.info(`Created caregiver invitation ${relId} from ${ownerUserId} to ${caregiverUserId}`);
    return { success: true, relationshipId: relId };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to create caregiver invitation.");
  }
});

export const acceptCaregiverInvitation = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const caregiverUserId = request.auth.uid;
  const relationshipId = request.data?.relationshipId;

  if (!relationshipId) throw new HttpsError("invalid-argument", "relationshipId required.");

  try {
    const relDoc = await db.collection("caregiver_relationships").doc(relationshipId).get();
    if (!relDoc.exists || relDoc.data()?.caregiverUserId !== caregiverUserId) {
      throw new HttpsError("permission-denied", "Unauthorized.");
    }

    await relDoc.ref.update({
      invitationStatus: "accepted",
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to accept invitation.");
  }
});

export const declineCaregiverInvitation = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const caregiverUserId = request.auth.uid;
  const relationshipId = request.data?.relationshipId;

  if (!relationshipId) throw new HttpsError("invalid-argument", "relationshipId required.");

  try {
    const relDoc = await db.collection("caregiver_relationships").doc(relationshipId).get();
    if (!relDoc.exists || relDoc.data()?.caregiverUserId !== caregiverUserId) {
      throw new HttpsError("permission-denied", "Unauthorized.");
    }

    await relDoc.ref.update({
      invitationStatus: "declined",
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to decline invitation.");
  }
});

export const revokeCaregiverAccess = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const userId = request.auth.uid;
  const relationshipId = request.data?.relationshipId;

  if (!relationshipId) throw new HttpsError("invalid-argument", "relationshipId required.");

  try {
    const relDoc = await db.collection("caregiver_relationships").doc(relationshipId).get();
    if (!relDoc.exists) throw new HttpsError("not-found", "Relationship not found.");

    const rData = relDoc.data()!;
    if (rData.ownerUserId !== userId && rData.caregiverUserId !== userId) {
      throw new HttpsError("permission-denied", "Unauthorized.");
    }

    await relDoc.ref.update({
      invitationStatus: "revoked",
      revokedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to revoke caregiver access.");
  }
});

