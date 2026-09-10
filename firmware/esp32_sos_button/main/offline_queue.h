#ifndef OFFLINE_QUEUE_H
#define OFFLINE_QUEUE_H

#include <string>
#include <vector>

struct QueueEvent {
    std::string eventId;
    std::string eventType;
    int batteryLevel;
    int64_t timestamp;
};

class OfflineQueue {
public:
    static void push(const QueueEvent& event);
    static bool pop(QueueEvent& outEvent);
    static bool isEmpty();
    static size_t size();
};

#endif // OFFLINE_QUEUE_H
