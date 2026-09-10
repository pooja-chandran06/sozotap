#ifndef SOS_BUTTON_H
#define SOS_BUTTON_H

#include <functional>

class SosButton {
public:
    using ButtonCallback = std::function<void()>;
    static void init(int gpioPin, ButtonCallback onSosTriggered);
    static void checkButtonState();
};

#endif // SOS_BUTTON_H
