"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FcmService = void 0;
const messaging_1 = require("firebase-admin/messaging");
const firestore_1 = require("firebase-admin/firestore");
const logger_1 = require("../utils/logger");
const redaction_1 = require("../utils/redaction");
class FcmService {
    constructor() {
        this.messaging = (0, messaging_1.getMessaging)();
        this.db = (0, firestore_1.getFirestore)();
    }
    /**
     * Sends FCM notification messages safely.
     * If a device token is stale/invalid/unregistered, disables it in Firestore.
     */
    async sendMessages(messages) {
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
                    logger_1.safeLogger.info(`FCM message dispatched to token ${(0, redaction_1.redactFcmToken)(meta.tokenId)}`);
                }
                else {
                    failureCount++;
                    const errCode = res.error?.code || "unknown_fcm_error";
                    logger_1.safeLogger.warn(`FCM message send failed for token ${(0, redaction_1.redactFcmToken)(meta.tokenId)}: ${errCode}`);
                    if (errCode === "messaging/registration-token-not-registered" ||
                        errCode === "messaging/invalid-registration-token") {
                        logger_1.safeLogger.info(`Disabling invalid FCM token ${(0, redaction_1.redactFcmToken)(meta.tokenId)} for user ${meta.ownerUserId}`);
                        await this.disableStaleToken(meta.ownerUserId, meta.tokenId);
                    }
                }
            }
        }
        catch (error) {
            logger_1.safeLogger.error("Failed to execute FCM multicast sendEach", error);
            failureCount += messages.length;
        }
        return { successCount, failureCount };
    }
    async disableStaleToken(userId, tokenId) {
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
        }
        catch (err) {
            logger_1.safeLogger.warn(`Could not disable stale token ${(0, redaction_1.redactFcmToken)(tokenId)}`, { userId });
        }
    }
}
exports.FcmService = FcmService;
//# sourceMappingURL=fcm_service.js.map