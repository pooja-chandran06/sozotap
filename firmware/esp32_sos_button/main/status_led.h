#ifndef STATUS_LED_H
#define STATUS_LED_H

enum class LedState {
    Unpaired,
    Pairing,
    Connecting,
    SosSent,
    Error,
    LowBattery
};

class StatusLed {
public:
    static void init(int pin);
    static void setState(LedState state);
};

#endif // STATUS_LED_H
