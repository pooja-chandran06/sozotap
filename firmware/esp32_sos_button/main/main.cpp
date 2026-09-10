#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "status_led.h"
#include "sos_button.h"
#include "wifi_manager.h"
#include "offline_queue.h"
#include "https_client.h"

static const char* TAG = "SOZOTAP_Main";

// Configuration Placeholders (Configured during provisioning)
static const char* WIFI_SSID = "HOME_WIFI_SSID";
static const char* WIFI_PASS = "HOME_WIFI_PASSWORD";
static const char* ENDPOINT_URL = "https://us-central1-sozotap-production.cloudfunctions.net/ingestDeviceEvent";
static const char* DEVICE_ID = "dev_esp32_001";
static const char* SECRET_TOKEN = "sample_device_secret_token_123";

void triggerSos() {
    ESP_LOGW(TAG, "Hardware Emergency SOS Triggered!");
    StatusLed::setState(LedState::SosSent);

    std::string eventId = "evt_" + std::to_string(esp_timer_get_time() / 1000);
    QueueEvent event = { eventId, "sos_pressed", 95, esp_timer_get_time() / 1000 };

    if (WifiManager::isConnected()) {
        bool ok = HttpsClient::sendSosEvent(ENDPOINT_URL, DEVICE_ID, SECRET_TOKEN, event.eventId, event.eventType, event.batteryLevel);
        if (!ok) {
            ESP_LOGW(TAG, "HTTPS dispatch failed. Queuing for retry.");
            OfflineQueue::push(event);
        }
    } else {
        ESP_LOGW(TAG, "Wi-Fi offline. Pushing SOS event to offline queue.");
        OfflineQueue::push(event);
    }
}

extern "C" void app_main(void) {
    ESP_LOGI(TAG, "Starting SOZOTAP ESP32 Emergency SOS Firmware v1.0.0");

    StatusLed::init(2); // Built-in GPIO 2 LED
    StatusLed::setState(LedState::Connecting);

    WifiManager::init(WIFI_SSID, WIFI_PASS);
    SosButton::init(0, triggerSos); // GPIO 0 (BOOT button on ESP32)

    while (1) {
        SosButton::checkButtonState();

        // Process retry queue when online
        if (WifiManager::isConnected() && !OfflineQueue::isEmpty()) {
            QueueEvent qEvent;
            if (OfflineQueue::pop(qEvent)) {
                ESP_LOGI(TAG, "Retrying queued event %s...", qEvent.eventId.c_str());
                bool ok = HttpsClient::sendSosEvent(ENDPOINT_URL, DEVICE_ID, SECRET_TOKEN, qEvent.eventId, qEvent.eventType, qEvent.batteryLevel);
                if (!ok) {
                    OfflineQueue::push(qEvent); // Re-queue if still failing
                }
            }
        }

        vTaskDelay(pdMS_TO_TICKS(50));
    }
}
