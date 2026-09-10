#include "https_client.h"
#include "esp_http_client.h"
#include "esp_log.h"
#include "esp_tls.h"

static const char* TAG = "HttpsClient";

// Trusted Root CA Certificate bundle for Firebase/Google Cloud HTTPS Endpoints
static const char google_root_ca_pem[] = 
"-----BEGIN CERTIFICATE-----\n"
"MIIF2DCCA8ACCQCMsWc0+Q...[GTS Root R1 Certificate]...\n"
"-----END CERTIFICATE-----\n";

bool HttpsClient::sendSosEvent(
    const std::string& serverUrl,
    const std::string& deviceId,
    const std::string& secretToken,
    const std::string& eventId,
    const std::string& eventType,
    int batteryLevel
) {
    std::string postData = "{\"data\":{"
        "\"deviceId\":\"" + deviceId + "\","
        "\"secretToken\":\"" + secretToken + "\","
        "\"eventId\":\"" + eventId + "\","
        "\"eventType\":\"" + eventType + "\","
        "\"batteryLevel\":" + std::to_string(batteryLevel) +
    "}}";

    esp_http_client_config_t config = {};
    config.url = serverUrl.c_str();
    config.cert_pem = google_root_ca_pem; // Strict TLS Certificate Verification
    config.method = HTTP_METHOD_POST;
    config.timeout_ms = 8000;

    esp_http_client_handle_t client = esp_http_client_init(&config);
    if (!client) {
        ESP_LOGE(TAG, "Failed to initialize HTTP client");
        return false;
    }

    esp_http_client_set_header(client, "Content-Type", "application/json");
    esp_http_client_set_post_field(client, postData.c_str(), postData.length());

    esp_err_t err = esp_http_client_perform(client);
    bool success = false;

    if (err == ESP_OK) {
        int statusCode = esp_http_client_get_status_code(client);
        ESP_LOGI(TAG, "HTTPS Ingest status = %d", statusCode);
        if (statusCode >= 200 && statusCode < 300) {
            success = true;
        }
    } else {
        ESP_LOGE(TAG, "HTTPS POST failed: %s", esp_err_to_name(err));
    }

    esp_http_client_cleanup(client);
    return success;
}
