"use strict";
/**
 * Redacts sensitive user and biological/location information from logs.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.redactPhoneNumber = redactPhoneNumber;
exports.redactFcmToken = redactFcmToken;
exports.redactEmail = redactEmail;
exports.sanitizeLogObject = sanitizeLogObject;
function redactPhoneNumber(phone) {
    if (!phone)
        return "[REDACTED_PHONE_EMPTY]";
    const trimmed = phone.trim();
    if (trimmed.length <= 4)
        return "****";
    return `${trimmed.slice(0, 3)}****${trimmed.slice(-2)}`;
}
function redactFcmToken(token) {
    if (!token)
        return "[REDACTED_TOKEN_EMPTY]";
    if (token.length <= 10)
        return "[REDACTED_TOKEN]";
    return `${token.slice(0, 6)}...${token.slice(-4)}`;
}
function redactEmail(email) {
    if (!email)
        return "[REDACTED_EMAIL_EMPTY]";
    const parts = email.split("@");
    if (parts.length !== 2)
        return "[REDACTED_EMAIL]";
    return `${parts[0].charAt(0)}***@${parts[1]}`;
}
function sanitizeLogObject(obj) {
    const sanitized = {};
    for (const [key, value] of Object.entries(obj)) {
        const lowerKey = key.toLowerCase();
        if (lowerKey.includes("phone")) {
            sanitized[key] = redactPhoneNumber(String(value));
        }
        else if (lowerKey.includes("token") || lowerKey.includes("secret") || lowerKey.includes("auth")) {
            sanitized[key] = redactFcmToken(String(value));
        }
        else if (lowerKey.includes("email")) {
            sanitized[key] = redactEmail(String(value));
        }
        else if (lowerKey.includes("latitude") ||
            lowerKey.includes("longitude") ||
            lowerKey.includes("gps") ||
            lowerKey.includes("allerg") ||
            lowerKey.includes("medicat") ||
            lowerKey.includes("diagnos") ||
            lowerKey.includes("condition")) {
            sanitized[key] = "[REDACTED_SENSITIVE_DATA]";
        }
        else if (typeof value === "object" && value !== null) {
            sanitized[key] = sanitizeLogObject(value);
        }
        else {
            sanitized[key] = value;
        }
    }
    return sanitized;
}
//# sourceMappingURL=redaction.js.map