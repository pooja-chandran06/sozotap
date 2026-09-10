#include "sos_button.h"
#include "driver/gpio.h"
#include "esp_timer.h"
#include "esp_log.h"

static const char* TAG = "SosButton";
static int s_button_pin = -1;
static SosButton::ButtonCallback s_callback = nullptr;
static int64_t s_press_start_time = 0;
static bool s_is_pressed = false;

void SosButton::init(int gpioPin, ButtonCallback onSosTriggered) {
    s_button_pin = gpioPin;
    s_callback = onSosTriggered;

    gpio_config_t io_conf = {};
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_INPUT;
    io_conf.pin_bit_mask = (1ULL << gpioPin);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en = GPIO_PULLUP_ENABLE;
    gpio_config(&io_conf);

    ESP_LOGI(TAG, "SOS Button initialized on GPIO %d (Active Low, 2s hold required)", gpioPin);
}

void SosButton::checkButtonState() {
    if (s_button_pin < 0 || !s_callback) return;

    int level = gpio_get_level((gpio_num_t)s_button_pin);
    int64_t now = esp_timer_get_time() / 1000; // ms

    if (level == 0) { // Pressed (active low)
        if (!s_is_pressed) {
            s_is_pressed = true;
            s_press_start_time = now;
        } else if ((now - s_press_start_time) >= 2000) { // 2s hold confirmed
            ESP_LOGW(TAG, "2-second SOS button hold confirmed! Triggering emergency alert.");
            s_callback();
            s_is_pressed = false; // Reset to avoid duplicate continuous triggers
        }
    } else {
        s_is_pressed = false;
    }
}
