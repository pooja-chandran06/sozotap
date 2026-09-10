import * as functionsLogger from "firebase-functions/logger";
import { sanitizeLogObject } from "./redaction";

export const safeLogger = {
  info: (message: string, data?: Record<string, any>) => {
    if (data) {
      functionsLogger.info(message, sanitizeLogObject(data));
    } else {
      functionsLogger.info(message);
    }
  },
  warn: (message: string, data?: Record<string, any>) => {
    if (data) {
      functionsLogger.warn(message, sanitizeLogObject(data));
    } else {
      functionsLogger.warn(message);
    }
  },
  error: (message: string, error?: any, data?: Record<string, any>) => {
    const sanitizedData = data ? sanitizeLogObject(data) : {};
    functionsLogger.error(message, { error: error?.message || error, ...sanitizedData });
  },
};
