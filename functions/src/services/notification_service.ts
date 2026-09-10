import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { NotificationRecord } from "../types";
import { safeLogger } from "../utils/logger";

export class NotificationService {
  private db = getFirestore();

  async createNotification(data: {
    recipientUserId: string;
    senderUserId: string;
    title: string;
    body: string;
    type: "sos_alert" | "sos_resolved" | "system";
    alertId?: string;
  }): Promise<string> {
    try {
      const notificationRef = this.db.collection("notifications").doc();
      const record: NotificationRecord = {
        notificationId: notificationRef.id,
        recipientUserId: data.recipientUserId,
        senderUserId: data.senderUserId,
        title: data.title,
        body: data.body,
        type: data.type,
        alertId: data.alertId,
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      };

      await notificationRef.set(record);
      safeLogger.info(`Created inbox notification ${notificationRef.id} for user ${data.recipientUserId}`);
      return notificationRef.id;
    } catch (error) {
      safeLogger.error("Failed to create inbox notification record", error);
      return "";
    }
  }
}
