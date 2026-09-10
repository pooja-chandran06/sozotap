"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationService = void 0;
const firestore_1 = require("firebase-admin/firestore");
const logger_1 = require("../utils/logger");
class NotificationService {
    constructor() {
        this.db = (0, firestore_1.getFirestore)();
    }
    async createNotification(data) {
        try {
            const notificationRef = this.db.collection("notifications").doc();
            const record = {
                notificationId: notificationRef.id,
                recipientUserId: data.recipientUserId,
                senderUserId: data.senderUserId,
                title: data.title,
                body: data.body,
                type: data.type,
                alertId: data.alertId,
                isRead: false,
                createdAt: firestore_1.FieldValue.serverTimestamp(),
            };
            await notificationRef.set(record);
            logger_1.safeLogger.info(`Created inbox notification ${notificationRef.id} for user ${data.recipientUserId}`);
            return notificationRef.id;
        }
        catch (error) {
            logger_1.safeLogger.error("Failed to create inbox notification record", error);
            return "";
        }
    }
}
exports.NotificationService = NotificationService;
//# sourceMappingURL=notification_service.js.map