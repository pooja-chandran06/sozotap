"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CONFIG = exports.twilioFromNumberSecret = exports.twilioAuthTokenSecret = exports.twilioAccountSidSecret = exports.smsProviderSecret = void 0;
const params_1 = require("firebase-functions/params");
exports.smsProviderSecret = (0, params_1.defineSecret)("SMS_PROVIDER");
exports.twilioAccountSidSecret = (0, params_1.defineSecret)("TWILIO_ACCOUNT_SID");
exports.twilioAuthTokenSecret = (0, params_1.defineSecret)("TWILIO_AUTH_TOKEN");
exports.twilioFromNumberSecret = (0, params_1.defineSecret)("TWILIO_FROM_NUMBER");
exports.CONFIG = {
    APP_NAME: "SOZOTAP",
    DEFAULT_NOTIFICATION_TITLE: "SOS Alert",
    DEFAULT_NOTIFICATION_BODY: "A trusted contact may need help. Tap to view the alert.",
    RESOLVED_NOTIFICATION_TITLE: "SOS Alert Resolved",
    RESOLVED_NOTIFICATION_BODY: "The emergency alert triggered by your contact has been marked resolved.",
    SMS_DEFAULT_MESSAGE: "SOZOTAP SOS Alert: A trusted contact may need help. Open the SOZOTAP app or contact them directly.",
};
//# sourceMappingURL=config.js.map