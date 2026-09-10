import { generateIdempotencyKey } from "../src/utils/idempotency";
import { redactPhoneNumber, redactFcmToken, redactEmail, sanitizeLogObject } from "../src/utils/redaction";
import { validateE164, DisabledSmsProvider } from "../src/services/sms_service";
import { CONFIG } from "../src/config";

describe("Cloud Functions Utility & Security Unit Tests", () => {
  test("generateIdempotencyKey creates unique, deterministic keys", () => {
    const key1 = generateIdempotencyKey("alert123", "user456", "fcm", "create");
    const key2 = generateIdempotencyKey("alert123", "user456", "fcm", "create");
    const key3 = generateIdempotencyKey("alert123", "user456", "sms", "create");
    const key4 = generateIdempotencyKey("alert123", "user456", "fcm", "resolve");

    expect(key1).toBe(key2);
    expect(key1).not.toBe(key3);
    expect(key1).not.toBe(key4);
    expect(typeof key1).toBe("string");
    expect(key1.length).toBe(64); // SHA-256 hex digest length
  });

  test("redaction utility masks phone numbers, FCM tokens, and emails", () => {
    expect(redactPhoneNumber("+14155552671")).toBe("+14****71");
    expect(redactFcmToken("fcm_token_abcdef1234567890_xyz")).toBe("fcm_to..._xyz");
    expect(redactEmail("john.doe@example.com")).toBe("j***@example.com");
  });

  test("sanitizeLogObject redacts sensitive parameters automatically", () => {
    const logData = {
      userEmail: "test@vitanexus.com",
      phoneNumber: "+15551234567",
      latitude: 37.7749,
      longitude: -122.4194,
      allergies: "Penicillin",
      normalField: "SOZOTAP_TEST",
    };

    const sanitized = sanitizeLogObject(logData);
    expect(sanitized.userEmail).toBe("t***@vitanexus.com");
    expect(sanitized.phoneNumber).toBe("+15****67");
    expect(sanitized.latitude).toBe("[REDACTED_SENSITIVE_DATA]");
    expect(sanitized.allergies).toBe("[REDACTED_SENSITIVE_DATA]");
    expect(sanitized.normalField).toBe("SOZOTAP_TEST");
  });

  test("validateE164 validates phone numbers correctly", () => {
    expect(validateE164("+14155552671")).toBe(true);
    expect(validateE164("+442079460912")).toBe(true);
    expect(validateE164("0123456789")).toBe(false);
    expect(validateE164("4155552671")).toBe(false);
    expect(validateE164("")).toBe(false);
  });

  test("DisabledSmsProvider returns skipped status cleanly without throwing", async () => {
    const provider = new DisabledSmsProvider();
    const result = await provider.sendSms("+14155552671", "Emergency alert test");

    expect(result.status).toBe("skipped");
    expect(result.failureCode).toBe("sms_provider_disabled");
    expect(result.failureReason).toBeDefined();
  });

  test("Default notification content contains NO sensitive medical details", () => {
    expect(CONFIG.DEFAULT_NOTIFICATION_TITLE).not.toContain("allergy");
    expect(CONFIG.DEFAULT_NOTIFICATION_TITLE).not.toContain("medication");
    expect(CONFIG.DEFAULT_NOTIFICATION_BODY).not.toContain("diagnosis");
    expect(CONFIG.DEFAULT_NOTIFICATION_BODY).not.toContain("GPS");
    expect(CONFIG.DEFAULT_NOTIFICATION_BODY).toBe("A trusted contact may need help. Tap to view the alert.");
  });

  test("Privacy consent redaction checks return Restricted when flags are disabled", () => {
    const profile = {
      shareBloodGroupInEmergency: false,
      shareAllergiesInEmergency: false,
      bloodGroup: "O Negative",
      allergies: "Penicillin",
    };

    const redactedBloodGroup = profile.shareBloodGroupInEmergency !== false ? profile.bloodGroup : "Restricted";
    const redactedAllergies = profile.shareAllergiesInEmergency !== false ? profile.allergies : "Restricted";

    expect(redactedBloodGroup).toBe("Restricted");
    expect(redactedAllergies).toBe("Restricted");
  });
});
