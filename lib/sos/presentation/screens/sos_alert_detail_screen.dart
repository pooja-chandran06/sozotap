import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SosAlertDetailScreen extends StatelessWidget {
  final String alertId;

  const SosAlertDetailScreen({super.key, required this.alertId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Emergency SOS Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('emergency_alerts').doc(alertId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B30)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('SOS Alert not found or has been deleted.', style: TextStyle(color: Colors.white)),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'unknown';
          final isActive = status == 'active';

          final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final formattedTime = DateFormat('MMMM d, yyyy - h:mm:ss a').format(createdAt);

          final location = data['location'] as Map<String, dynamic>?;
          final latitude = location?['latitude'];
          final longitude = location?['longitude'];

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert Banner Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFFF3B30).withOpacity(0.15) : const Color(0xFF30D158).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? const Color(0xFFFF3B30) : const Color(0xFF30D158),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isActive ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                        color: isActive ? const Color(0xFFFF3B30) : const Color(0xFF30D158),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isActive ? 'ACTIVE EMERGENCY ALERT' : 'ALERT RESOLVED',
                        style: TextStyle(
                          color: isActive ? const Color(0xFFFF3B30) : const Color(0xFF30D158),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formattedTime,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text('ALERT DETAILS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Alert ID', alertId),
                      const Divider(color: Color(0xFF2C2C2E)),
                      _buildInfoRow('Status', status.toUpperCase()),
                      const Divider(color: Color(0xFF2C2C2E)),
                      _buildInfoRow(
                        'Location Attached',
                        latitude != null && longitude != null ? 'Coordinates Available' : 'No GPS Location',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                if (latitude != null && longitude != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A84FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
                        if (await canLaunchUrl(googleMapsUrl)) {
                          await launchUrl(googleMapsUrl);
                        }
                      },
                      icon: const Icon(Icons.map, color: Colors.white),
                      label: const Text('Open Map Location', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF3B30)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final uri = Uri.parse('tel:112');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.phone_in_talk, color: Color(0xFFFF3B30)),
                    label: const Text('Call Local Emergency Services', style: TextStyle(color: Color(0xFFFF3B30), fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
