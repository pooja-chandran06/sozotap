idf_component_register(
    SRCS 
        "main.cpp"
        "wifi_manager.cpp"
        "https_client.cpp"
        "sos_button.cpp"
        "status_led.cpp"
        "offline_queue.cpp"
    INCLUDE_DIRS "."
    REQUIRES 
        nvs_flash
        esp_wifi
        esp_event
        esp_http_client
        esp_tls
        driver
        lwip
)
