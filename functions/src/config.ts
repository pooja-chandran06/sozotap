import { defineSecret } from "firebase-functions/params";

export const smsProviderSecret = defineSecret("SMS_PROVIDER");
export const twilioAccountSidSecret = defineSecret("TWILIO_ACCOUNT_SID");
export const twilioAuthTokenSecret = defineSecret("TWILIO_AUTH_TOKEN");
export const twilioFromNumberSecret = defineSecret("TWILIO_FROM_NUMBER");

export const CONFIG = {
  APP_NAME: "SOZOTAP",
  DEFAULT_NOTIFICATION_TITLE: "SOS Alert",
  DEFAULT_NOTIFICATION_BODY: "A trusted contact may need help. Tap to view the alert.",
  RESOLVED_NOTIFICATION_TITLE: "SOS Alert Resolved",
  RESOLVED_NOTIFICATION_BODY: "The emergency alert triggered by your contact has been marked resolved.",
  SMS_DEFAULT_MESSAGE: "SOZOTAP SOS Alert: A trusted contact may need help. Open the SOZOTAP app or contact them directly.",
};
