#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

class WifiManager {
public:
    static void init(const char* ssid, const char* password);
    static bool isConnected();
};

#endif // WIFI_MANAGER_H
