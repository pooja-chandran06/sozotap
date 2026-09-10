import * as crypto from "crypto";

export function generateIdempotencyKey(
  alertId: string,
  recipientId: string,
  channel: "fcm" | "sms",
  action: "create" | "resolve" = "create"
): string {
  const raw = `${action}_${alertId}_${recipientId}_${channel}`;
  return crypto.createHash("sha256").update(raw).digest("hex");
}
