enum DeviceEventType { sos_pressed, battery_low, connection_lost, location_update, fall_candidate }
enum DeviceEventStatus { received, confirmed, processed, ignored, failed }

class DeviceEvent {
  final String eventId;
  final String deviceId;
  final String ownerUserId;
  final DeviceEventType type;
  final DateTime createdAt;
  final DeviceEventStatus status;
  final int? batteryLevel;
  final Map<String, dynamic> payload;
  final String idempotencyKey;

  DeviceEvent({
    required this.eventId,
    required this.deviceId,
    required this.ownerUserId,
    required this.type,
    required this.createdAt,
    required this.status,
    this.batteryLevel,
    this.payload = const {},
    required this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'deviceId': deviceId,
      'ownerUserId': ownerUserId,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'batteryLevel': batteryLevel,
      'payload': payload,
      'idempotencyKey': idempotencyKey,
    };
  }

  factory DeviceEvent.fromJson(Map<String, dynamic> json) {
    return DeviceEvent(
      eventId: json['eventId'] as String,
      deviceId: json['deviceId'] as String,
      ownerUserId: json['ownerUserId'] as String,
      type: DeviceEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DeviceEventType.sos_pressed,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: DeviceEventStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeviceEventStatus.received,
      ),
      batteryLevel: json['batteryLevel'] as int?,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      idempotencyKey: json['idempotencyKey'] as String,
    );
  }
}
