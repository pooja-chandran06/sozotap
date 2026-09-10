import { getMessaging, Message } from "firebase-admin/messaging";
import { getFirestore } from "firebase-admin/firestore";
import { safeLogger } from "../utils/logger";
import { redactFcmToken } from "../utils/redaction";

export class FcmService {
  private messaging = getMessaging();
  private db = getFirestore();

  /**
   * Sends FCM notification messages safely.
   * If a device token is stale/invalid/unregistered, disables it in Firestore.
   */
  async sendMessages(
    messages: Array<{ message: Message; ownerUserId: string; tokenId: string }>
  ): Promise<{ successCount: number; failureCount: number }> {
    if (messages.length === 0) {
      return { successCount: 0, failureCount: 0 };
    }

    let successCount = 0;
    let failureCount = 0;

    const rawMessages = messages.map((m) => m.message);

    try {
      const response = await this.messaging.sendEach(rawMessages);
      
      for (let i = 0; i < response.responses.length; i++) {
        const res = response.responses[i];
        const meta = messages[i];

        if (res.success) {
          successCount++;
          safeLogger.info(`FCM message dispatched to token ${redactFcmToken(meta.tokenId)}`);
        } else {
          failureCount++;
          const errCode = res.error?.code || "unknown_fcm_error";
          safeLogger.warn(`FCM message send failed for token ${redactFcmToken(meta.tokenId)}: ${errCode}`);

          if (
            errCode === "messaging/registration-token-not-registered" ||
            errCode === "messaging/invalid-registration-token"
          ) {
            safeLogger.info(`Disabling invalid FCM token ${redactFcmToken(meta.tokenId)} for user ${meta.ownerUserId}`);
            await this.disableStaleToken(meta.ownerUserId, meta.tokenId);
          }
        }
      }
    } catch (error) {
      safeLogger.error("Failed to execute FCM multicast sendEach", error);
      failureCount += messages.length;
    }

    return { successCount, failureCount };
  }

  private async disableStaleToken(userId: string, tokenId: string): Promise<void> {
    try {
      await this.db
        .collection("users")
        .doc(userId)
        .collection("device_tokens")
        .doc(tokenId)
        .update({
          enabled: false,
          updatedAt: new Date().toISOString(),
        });
    } catch (err) {
      safeLogger.warn(`Could not disable stale token ${redactFcmToken(tokenId)}`, { userId });
    }
  }
}
