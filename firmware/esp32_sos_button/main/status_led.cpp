#include "status_led.h"
#include "driver/gpio.h"
#include "esp_log.h"

static const char* TAG = "StatusLed";
static int s_led_pin = -1;

void StatusLed::init(int pin) {
    s_led_pin = pin;
    gpio_config_t io_conf = {};
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << pin);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
    gpio_config(&io_conf);
    ESP_LOGI(TAG, "Status LED initialized on GPIO %d", pin);
}

void StatusLed::setState(LedState state) {
    if (s_led_pin < 0) return;

    switch (state) {
        case LedState::SosSent:
            gpio_set_level((gpio_num_t)s_led_pin, 1);
            break;
        case LedState::Error:
        case LedState::LowBattery:
            gpio_set_level((gpio_num_t)s_led_pin, 1);
            break;
        default:
            gpio_set_level((gpio_num_t)s_led_pin, 0);
            break;
    }
}
