enum ConnectionType { ble, wifi, gsm, nfc }
enum DeviceStatus { unpaired, pairing, paired, disconnected, revoked }

class IoTDevice {
  final String deviceId;
  final String ownerUserId;
  final String displayName;
  final ConnectionType connectionType;
  final DeviceStatus status;
  final String? firmwareVersion;
  final int? batteryLevel;
  final DateTime? lastSeenAt;
  final DateTime pairedAt;
  final DateTime? revokedAt;
  final bool sosEnabled;
  final bool deviceLocationEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  IoTDevice({
    required this.deviceId,
    required this.ownerUserId,
    required this.displayName,
    required this.connectionType,
    required this.status,
    this.firmwareVersion,
    this.batteryLevel,
    this.lastSeenAt,
    required this.pairedAt,
    this.revokedAt,
    this.sosEnabled = true,
    this.deviceLocationEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'ownerUserId': ownerUserId,
      'displayName': displayName,
      'connectionType': connectionType.name,
      'status': status.name,
      'firmwareVersion': firmwareVersion,
      'batteryLevel': batteryLevel,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'pairedAt': pairedAt.toIso8601String(),
      'revokedAt': revokedAt?.toIso8601String(),
      'sosEnabled': sosEnabled,
      'deviceLocationEnabled': deviceLocationEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory IoTDevice.fromJson(Map<String, dynamic> json) {
    return IoTDevice(
      deviceId: json['deviceId'] as String,
      ownerUserId: json['ownerUserId'] as String,
      displayName: json['displayName'] as String,
      connectionType: ConnectionType.values.firstWhere(
        (e) => e.name == json['connectionType'],
        orElse: () => ConnectionType.ble,
      ),
      status: DeviceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeviceStatus.paired,
      ),
      firmwareVersion: json['firmwareVersion'] as String?,
      batteryLevel: json['batteryLevel'] as int?,
      lastSeenAt: json['lastSeenAt'] != null ? DateTime.parse(json['lastSeenAt'] as String) : null,
      pairedAt: DateTime.parse(json['pairedAt'] as String),
      revokedAt: json['revokedAt'] != null ? DateTime.parse(json['revokedAt'] as String) : null,
      sosEnabled: json['sosEnabled'] as bool? ?? true,
      deviceLocationEnabled: json['deviceLocationEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  IoTDevice copyWith({
    String? displayName,
    DeviceStatus? status,
    int? batteryLevel,
    DateTime? lastSeenAt,
    DateTime? revokedAt,
    bool? sosEnabled,
    bool? deviceLocationEnabled,
  }) {
    return IoTDevice(
      deviceId: deviceId,
      ownerUserId: ownerUserId,
      displayName: displayName ?? this.displayName,
      connectionType: connectionType,
      status: status ?? this.status,
      firmwareVersion: firmwareVersion,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      pairedAt: pairedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      sosEnabled: sosEnabled ?? this.sosEnabled,
      deviceLocationEnabled: deviceLocationEnabled ?? this.deviceLocationEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
