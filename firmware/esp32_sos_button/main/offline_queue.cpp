#include "offline_queue.h"
#include "esp_log.h"

static const char* TAG = "OfflineQueue";
static const size_t MAX_CAPACITY = 10;
static std::vector<QueueEvent> s_queue;

void OfflineQueue::push(const QueueEvent& event) {
    if (s_queue.size() >= MAX_CAPACITY) {
        ESP_LOGW(TAG, "Queue full (capacity %zu). Dropping oldest pending event.", MAX_CAPACITY);
        s_queue.erase(s_queue.begin());
    }
    s_queue.push_back(event);
    ESP_LOGI(TAG, "Queued event %s. Total in queue: %zu", event.eventId.c_str(), s_queue.size());
}

bool OfflineQueue::pop(QueueEvent& outEvent) {
    if (s_queue.empty()) return false;
    outEvent = s_queue.front();
    s_queue.erase(s_queue.begin());
    return true;
}

bool OfflineQueue::isEmpty() {
    return s_queue.empty();
}

size_t OfflineQueue::size() {
    return s_queue.size();
}
