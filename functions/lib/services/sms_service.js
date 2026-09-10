"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SmsService = exports.TwilioSmsProvider = exports.DisabledSmsProvider = void 0;
exports.validateE164 = validateE164;
const config_1 = require("../config");
const logger_1 = require("../utils/logger");
const redaction_1 = require("../utils/redaction");
function validateE164(phone) {
    // E.164 regex: + followed by 7 to 15 digits
    const e164Regex = /^\+[1-9]\d{6,14}$/;
    return e164Regex.test(phone.trim());
}
class DisabledSmsProvider {
    async sendSms(toPhoneNumber, bodyText) {
        logger_1.safeLogger.info(`SMS dispatch skipped: No active SMS provider configured for ${(0, redaction_1.redactPhoneNumber)(toPhoneNumber)}`);
        return {
            status: "skipped",
            failureCode: "sms_provider_disabled",
            failureReason: "No real SMS provider credentials configured in environment or secrets. Contact SMS consent verified but delivery skipped safely.",
        };
    }
}
exports.DisabledSmsProvider = DisabledSmsProvider;
class TwilioSmsProvider {
    constructor(accountSid, authToken, fromNumber) {
        this.accountSid = accountSid;
        this.authToken = authToken;
        this.fromNumber = fromNumber;
    }
    async sendSms(toPhoneNumber, bodyText) {
        if (!validateE164(toPhoneNumber)) {
            logger_1.safeLogger.warn(`Invalid E.164 phone format for ${(0, redaction_1.redactPhoneNumber)(toPhoneNumber)}`);
            return {
                status: "failed",
                failureCode: "invalid_phone_number",
                failureReason: "Phone number is not in valid E.164 format (+[country_code][number])",
            };
        }
        try {
            const url = `https://api.twilio.com/2010-04-01/Accounts/${this.accountSid}/Messages.json`;
            const authHeader = "Basic " + Buffer.from(`${this.accountSid}:${this.authToken}`).toString("base64");
            const params = new URLSearchParams();
            params.append("To", toPhoneNumber);
            params.append("From", this.fromNumber);
            params.append("Body", bodyText);
            const response = await fetch(url, {
                method: "POST",
                headers: {
                    Authorization: authHeader,
                    "Content-Type": "application/x-www-form-urlencoded",
                },
                body: params.toString(),
            });
            const resData = await response.json();
            if (response.ok) {
                logger_1.safeLogger.info(`Twilio SMS sent successfully to ${(0, redaction_1.redactPhoneNumber)(toPhoneNumber)}`, { sid: resData.sid });
                return {
                    status: "sent",
                    providerMessageId: resData.sid,
                };
            }
            else {
                logger_1.safeLogger.warn(`Twilio SMS API error for ${(0, redaction_1.redactPhoneNumber)(toPhoneNumber)}`, { code: resData.code, message: resData.message });
                return {
                    status: "failed",
                    failureCode: String(resData.code || response.status),
                    failureReason: resData.message || "Twilio API returned error status",
                };
            }
        }
        catch (error) {
            logger_1.safeLogger.error(`Exception executing Twilio SMS request for ${(0, redaction_1.redactPhoneNumber)(toPhoneNumber)}`, error);
            return {
                status: "failed",
                failureCode: "sms_network_exception",
                failureReason: error?.message || "Network exception during Twilio SMS send",
            };
        }
    }
}
exports.TwilioSmsProvider = TwilioSmsProvider;
class SmsService {
    constructor(provider) {
        if (provider) {
            this.provider = provider;
        }
        else {
            // Secret check logic at runtime
            const providerType = process.env.SMS_PROVIDER || "";
            const accountSid = process.env.TWILIO_ACCOUNT_SID || "";
            const authToken = process.env.TWILIO_AUTH_TOKEN || "";
            const fromNumber = process.env.TWILIO_FROM_NUMBER || "";
            if (providerType.toLowerCase() === "twilio" && accountSid && authToken && fromNumber) {
                this.provider = new TwilioSmsProvider(accountSid, authToken, fromNumber);
            }
            else {
                this.provider = new DisabledSmsProvider();
            }
        }
    }
    async sendEmergencySms(toPhoneNumber, customMessage) {
        const body = customMessage || config_1.CONFIG.SMS_DEFAULT_MESSAGE;
        return await this.provider.sendSms(toPhoneNumber, body);
    }
}
exports.SmsService = SmsService;
//# sourceMappingURL=sms_service.js.map