import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SosSessionData {
  final String sosId;
  final String userId;
  final String patientName;
  final String bloodGroup;
  final String medicalConditions;
  final String status; // 'active' | 'resolved' | 'cancelled'
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SosSessionData({
    required this.sosId,
    required this.userId,
    required this.patientName,
    required this.bloodGroup,
    required this.medicalConditions,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SosSessionData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final GeoPoint location = data['currentLocation'] as GeoPoint? ?? const GeoPoint(0, 0);

    return SosSessionData(
      sosId: doc.id,
      userId: data['userId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? 'Unknown Patient',
      bloodGroup: data['bloodGroup'] as String? ?? 'N/A',
      medicalConditions: data['medicalConditions'] as String? ?? 'None reported',
      status: data['status'] as String? ?? 'active',
      latitude: location.latitude,
      longitude: location.longitude,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

final sosDetailsProvider = StreamProvider.family<SosSessionData?, String>((ref, sosId) {
  return FirebaseFirestore.instance
      .collection('sos_sessions')
      .doc(sosId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return null;
        }
        return SosSessionData.fromFirestore(snapshot);
      });
});
