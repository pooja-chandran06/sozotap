import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
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
    if (profile.emergencyAccessEnabled === false) {
      safeLogger.warn(`Emergency access disabled by profile owner ${ownerUserId}`);
      throw new HttpsError("permission-denied", "unavailable");
    }

    let emergencyContacts: Array<any> = [];
    if (profile.shareContactsInEmergency !== false) {
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
      bloodGroup: profile.bloodGroup || "Not Specified",
      allergies: profile.allergies || "None reported",
      medicalConditions: profile.medicalConditions || "None reported",
      currentMedications: profile.currentMedications || "None reported",
      implants: profile.implants || "None reported",
      emergencyNotes: profile.notes || "",
      primaryDoctor: profile.shareDoctorHospitalInEmergency !== false ? profile.primaryDoctor : null,
      preferredHospital: profile.shareDoctorHospitalInEmergency !== false ? profile.preferredHospital : null,
      hospitalAddress:
        profile.shareDoctorHospitalInEmergency !== false && profile.shareDirectionsInEmergency !== false
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
      // 1. Fetch owner's emergency contacts
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

        // ---------------------------------------------------------------------
        // A. FCM DISPATCH LOGIC
        // ---------------------------------------------------------------------
        if (contact.recipientUserId && contact.allowPushNotifications !== false) {
          const recipientId = contact.recipientUserId;

          // Check recipient push preference
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
              // Fetch recipient device tokens
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

              // Create inbox notification record for user
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

        // ---------------------------------------------------------------------
        // B. SMS FALLBACK LOGIC
        // ---------------------------------------------------------------------
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

      // -----------------------------------------------------------------------
      // C. DISPATCH FCM BATCH
      // -----------------------------------------------------------------------
      if (fcmPayloads.length > 0) {
        const { successCount, failureCount } = await fcmService.sendMessages(fcmPayloads);

        // Record delivery logs for FCM attempts
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

    // Detect transition from active -> resolved or cancelled
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

            // Create resolution inbox notification
            await notificationService.createNotification({
              recipientUserId: recipientId,
              senderUserId: ownerUserId,
              title: CONFIG.RESOLVED_NOTIFICATION_TITLE,
              body: CONFIG.RESOLVED_NOTIFICATION_BODY,
              type: "sos_resolved",
              alertId: alertId,
            });

            // Send FCM resolution message
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
