#ifndef HTTPS_CLIENT_H
#define HTTPS_CLIENT_H

#include <string>

class HttpsClient {
public:
    static bool sendSosEvent(
        const std::string& serverUrl,
        const std::string& deviceId,
        const std::string& secretToken,
        const std::string& eventId,
        const std::string& eventType,
        int batteryLevel
    );
};

#endif // HTTPS_CLIENT_H
