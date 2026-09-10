"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DeliveryService = void 0;
const firestore_1 = require("firebase-admin/firestore");
const logger_1 = require("../utils/logger");
class DeliveryService {
    constructor() {
        this.db = (0, firestore_1.getFirestore)();
    }
    async recordDelivery(data) {
        try {
            const deliveryRef = this.db.collection("message_deliveries").doc();
            const deliveryRecord = {
                deliveryId: deliveryRef.id,
                alertId: data.alertId,
                recipientUserId: data.recipientUserId || null,
                recipientContactId: data.recipientContactId,
                channel: data.channel,
                status: data.status,
                providerMessageId: data.providerMessageId || null,
                failureCode: data.failureCode || null,
                failureReason: data.failureReason || null,
                createdAt: firestore_1.FieldValue.serverTimestamp(),
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
                idempotencyKey: data.idempotencyKey,
            };
            await deliveryRef.set(deliveryRecord);
            logger_1.safeLogger.info(`Recorded message delivery ${deliveryRef.id} status=${data.status} channel=${data.channel}`);
            return deliveryRef.id;
        }
        catch (error) {
            logger_1.safeLogger.error("Failed to record message delivery", error);
            return "";
        }
    }
    async isIdempotencyKeyProcessed(idempotencyKey) {
        try {
            const snapshot = await this.db
                .collection("message_deliveries")
                .where("idempotencyKey", "==", idempotencyKey)
                .limit(1)
                .get();
            return !snapshot.empty;
        }
        catch (error) {
            logger_1.safeLogger.error("Error checking idempotency key", error);
            return false; // Safely proceed if check fails to avoid missing critical notifications
        }
    }
}
exports.DeliveryService = DeliveryService;
//# sourceMappingURL=delivery_service.js.map