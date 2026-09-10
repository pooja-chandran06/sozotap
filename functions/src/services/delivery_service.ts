import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { MessageDelivery, DeliveryChannel, DeliveryStatus } from "../types";
import { safeLogger } from "../utils/logger";

export class DeliveryService {
  private db = getFirestore();

  async recordDelivery(data: {
    alertId: string;
    recipientUserId?: string | null;
    recipientContactId: string;
    channel: DeliveryChannel;
    status: DeliveryStatus;
    idempotencyKey: string;
    providerMessageId?: string | null;
    failureCode?: string | null;
    failureReason?: string | null;
  }): Promise<string> {
    try {
      const deliveryRef = this.db.collection("message_deliveries").doc();
      const deliveryRecord: MessageDelivery = {
        deliveryId: deliveryRef.id,
        alertId: data.alertId,
        recipientUserId: data.recipientUserId || null,
        recipientContactId: data.recipientContactId,
        channel: data.channel,
        status: data.status,
        providerMessageId: data.providerMessageId || null,
        failureCode: data.failureCode || null,
        failureReason: data.failureReason || null,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        idempotencyKey: data.idempotencyKey,
      };

      await deliveryRef.set(deliveryRecord);
      safeLogger.info(`Recorded message delivery ${deliveryRef.id} status=${data.status} channel=${data.channel}`);
      return deliveryRef.id;
    } catch (error) {
      safeLogger.error("Failed to record message delivery", error);
      return "";
    }
  }

  async isIdempotencyKeyProcessed(idempotencyKey: string): Promise<boolean> {
    try {
      const snapshot = await this.db
        .collection("message_deliveries")
        .where("idempotencyKey", "==", idempotencyKey)
        .limit(1)
        .get();

      return !snapshot.empty;
    } catch (error) {
      safeLogger.error("Error checking idempotency key", error);
      return false; // Safely proceed if check fails to avoid missing critical notifications
    }
  }
}
