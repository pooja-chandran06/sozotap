import { SmsResult } from "../types";
import { CONFIG } from "../config";
import { safeLogger } from "../utils/logger";
import { redactPhoneNumber } from "../utils/redaction";

export interface ISmsProvider {
  sendSms(toPhoneNumber: string, bodyText: string): Promise<SmsResult>;
}

export function validateE164(phone: string): boolean {
  // E.164 regex: + followed by 7 to 15 digits
  const e164Regex = /^\+[1-9]\d{6,14}$/;
  return e164Regex.test(phone.trim());
}

export class DisabledSmsProvider implements ISmsProvider {
  async sendSms(toPhoneNumber: string, bodyText: string): Promise<SmsResult> {
    safeLogger.info(`SMS dispatch skipped: No active SMS provider configured for ${redactPhoneNumber(toPhoneNumber)}`);
    return {
      status: "skipped",
      failureCode: "sms_provider_disabled",
      failureReason: "No real SMS provider credentials configured in environment or secrets. Contact SMS consent verified but delivery skipped safely.",
    };
  }
}

export class TwilioSmsProvider implements ISmsProvider {
  constructor(
    private accountSid: string,
    private authToken: string,
    private fromNumber: string
  ) {}

  async sendSms(toPhoneNumber: string, bodyText: string): Promise<SmsResult> {
    if (!validateE164(toPhoneNumber)) {
      safeLogger.warn(`Invalid E.164 phone format for ${redactPhoneNumber(toPhoneNumber)}`);
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
        safeLogger.info(`Twilio SMS sent successfully to ${redactPhoneNumber(toPhoneNumber)}`, { sid: resData.sid });
        return {
          status: "sent",
          providerMessageId: resData.sid,
        };
      } else {
        safeLogger.warn(`Twilio SMS API error for ${redactPhoneNumber(toPhoneNumber)}`, { code: resData.code, message: resData.message });
        return {
          status: "failed",
          failureCode: String(resData.code || response.status),
          failureReason: resData.message || "Twilio API returned error status",
        };
      }
    } catch (error: any) {
      safeLogger.error(`Exception executing Twilio SMS request for ${redactPhoneNumber(toPhoneNumber)}`, error);
      return {
        status: "failed",
        failureCode: "sms_network_exception",
        failureReason: error?.message || "Network exception during Twilio SMS send",
      };
    }
  }
}

export class SmsService {
  private provider: ISmsProvider;

  constructor(provider?: ISmsProvider) {
    if (provider) {
      this.provider = provider;
    } else {
      // Secret check logic at runtime
      const providerType = process.env.SMS_PROVIDER || "";
      const accountSid = process.env.TWILIO_ACCOUNT_SID || "";
      const authToken = process.env.TWILIO_AUTH_TOKEN || "";
      const fromNumber = process.env.TWILIO_FROM_NUMBER || "";

      if (providerType.toLowerCase() === "twilio" && accountSid && authToken && fromNumber) {
        this.provider = new TwilioSmsProvider(accountSid, authToken, fromNumber);
      } else {
        this.provider = new DisabledSmsProvider();
      }
    }
  }

  async sendEmergencySms(toPhoneNumber: string, customMessage?: string): Promise<SmsResult> {
    const body = customMessage || CONFIG.SMS_DEFAULT_MESSAGE;
    return await this.provider.sendSms(toPhoneNumber, body);
  }
}
