# SMS Provider Integration & Consent Guide

This document details SOZOTAP's SMS fallback architecture, consent policy, and Twilio integration.

---

## 🏛 Legal & Regulatory Compliance

1. **TCPA & International Regulations**: SMS messages sent to emergency contacts require explicit opt-in consent.
2. **Consent Recording**: Consent must be recorded in `EmergencyContact`:
   - `allowSmsNotifications = true`
   - `smsConsentAt = Timestamp`
3. **Carrier & Regional Variance**: Phone regulations, toll-free verification, and shortcode rules vary across countries (US, EU, India, UK). Users are informed in the app UI regarding potential SMS rates.

---

## 🔌 Extensible Provider Architecture

The backend includes a pluggable `ISmsProvider` interface:

```typescript
export interface ISmsProvider {
  sendSms(toPhoneNumber: string, bodyText: string): Promise<SmsResult>;
}
```

### Supported Implementations:
1. `TwilioSmsProvider`: Activated when environment secrets (`TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER`) are present.
2. `DisabledSmsProvider`: Safe fallback when secrets are omitted. Automatically logs delivery status as `skipped` with code `sms_provider_disabled`.

> [!NOTE]
> The `DisabledSmsProvider` ensures that absence of SMS secrets will NEVER crash Cloud Functions or fake successful delivery.

---

## 🧪 E.164 Phone Format Validation

All phone numbers are validated prior to dispatch:
- E.164 pattern: `^\+[1-9]\d{6,14}$` (e.g. `+14155552671`)
- Invalid numbers are flagged as `failed` with code `invalid_phone_number` in `message_deliveries`.

---

## 🔒 SMS Content Policy
Default message text:
> "SOZOTAP SOS Alert: A trusted contact may need help. Open the SOZOTAP app or contact them directly."

No medical diagnoses, allergies, or raw coordinates are broadcast via unencrypted SMS text.
