import { Timestamp, FieldValue } from "firebase-admin/firestore";

export type DeliveryChannel = "fcm" | "sms";
export type DeliveryStatus = "queued" | "sent" | "delivered" | "failed" | "skipped";

export interface EmergencyContact {
  contactId: string;
  ownerUserId: string;
  name: string;
  relationship: string;
  phoneNumber: string;
  priority: number;
  isPrimary: boolean;
  recipientUserId?: string | null;
  allowPushNotifications?: boolean;
  allowSmsNotifications?: boolean;
  smsConsentAt?: Timestamp | string | null;
  createdAt?: Timestamp | string;
  updatedAt?: Timestamp | string;
}

export interface DeviceToken {
  tokenId: string;
  ownerUserId: string;
  token: string;
  platform: string;
  appVersion?: string;
  notificationPermissionStatus?: string;
  enabled: boolean;
  createdAt?: Timestamp | string;
  updatedAt?: Timestamp | string;
  lastSeenAt?: Timestamp | string;
}

export interface NotificationPreference {
  sosPushEnabled?: boolean;
  sosSmsEnabled?: boolean;
  medicationReminderEnabled?: boolean;
  appointmentReminderEnabled?: boolean;
  qrScanAlertEnabled?: boolean;
  updatedAt?: Timestamp | string;
}

export interface MessageDelivery {
  deliveryId: string;
  alertId: string;
  recipientUserId?: string | null;
  recipientContactId: string;
  channel: DeliveryChannel;
  status: DeliveryStatus;
  providerMessageId?: string | null;
  failureCode?: string | null;
  failureReason?: string | null;
  createdAt: Timestamp | FieldValue;
  updatedAt: Timestamp | FieldValue;
  idempotencyKey: string;
}

export interface EmergencyAlert {
  alertId: string;
  ownerUserId: string;
  status: "active" | "resolved" | "cancelled";
  notificationStatus?: string;
  location?: {
    latitude: number;
    longitude: number;
    accuracy?: number;
    address?: string;
  } | null;
  createdAt: Timestamp;
  updatedAt?: Timestamp;
  resolvedAt?: Timestamp | null;
}

export interface NotificationRecord {
  notificationId: string;
  recipientUserId: string;
  senderUserId: string;
  title: string;
  body: string;
  type: "sos_alert" | "sos_resolved" | "system";
  alertId?: string;
  isRead: boolean;
  createdAt: Timestamp | FieldValue;
}

export interface SmsResult {
  status: DeliveryStatus;
  providerMessageId?: string;
  failureCode?: string;
  failureReason?: string;
}
