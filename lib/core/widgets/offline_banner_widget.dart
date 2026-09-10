import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OfflineBannerWidget extends StatelessWidget {
  final bool isOffline;
  final DateTime? lastSyncedAt;

  const OfflineBannerWidget({
    super.key,
    required this.isOffline,
    this.lastSyncedAt,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    final formattedSync = lastSyncedAt != null
        ? DateFormat('h:mm a, MMM d').format(lastSyncedAt!)
        : 'Never';

    return Container(
      width: double.infinity,
      color: const Color(0xFFD32F2F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Offline Mode — Displaying cached data',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Last synced: $formattedSync',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
