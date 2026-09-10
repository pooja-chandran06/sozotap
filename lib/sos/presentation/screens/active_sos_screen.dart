import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_config.dart';
import '../../../constants/app_colors.dart';
import '../../domain/models/emergency_alert_model.dart';
import '../providers/sos_providers.dart';

class ActiveSosScreen extends ConsumerStatefulWidget {
  final String alertId;

  const ActiveSosScreen({
    super.key,
    required this.alertId,
  });

  @override
  ConsumerState<ActiveSosScreen> createState() => _ActiveSosScreenState();
}

class _ActiveSosScreenState extends ConsumerState<ActiveSosScreen> {
  bool _isStopping = false;
  Timer? _elapsedTimer;
  Duration _elapsedDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startElapsedTimer();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = ref.read(sosControllerProvider);
      final alert = state.currentAlert;
      if (alert != null) {
        setState(() {
          _elapsedDuration = DateTime.now().difference(alert.createdAt);
        });
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _makeDirectEmergencyCall() async {
    final String emergencyNumber = AppConfig.defaultEmergencyNumber;
    final Uri launchUri = Uri(scheme: 'tel', path: emergencyNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open phone dialer for $emergencyNumber.')),
        );
      }
    }
  }

  Future<void> _confirmStopSos(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop SOS Broadcast?'),
        content: const Text(
          'Are you sure you want to stop this emergency alert? Live location tracking will end immediately and the alert will be marked resolved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop SOS'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isStopping = true);
      try {
        await ref.read(sosControllerProvider.notifier).stopSos(widget.alertId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SOS Alert resolved. Live tracking stopped.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to stop SOS: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isStopping = false);
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final alertAsync = ref.watch(watchAlertProvider(widget.alertId));
    final controllerState = ref.watch(sosControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EMERGENCY SOS ACTIVE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: alertAsync.when(
        data: (alert) {
          final EmergencyAlertModel currentAlert = alert ??
              controllerState.currentAlert ??
              EmergencyAlertModel(
                alertId: widget.alertId,
                ownerUserId: '',
                status: 'active',
                type: 'manual_sos',
                message: 'Emergency SOS alert',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                locationStatus: 'unavailable',
                liveLocationEnabled: false,
                expiresAt: DateTime.now().add(AppConfig.sosMaxActiveDuration),
                recipientContactIds: const [],
                notificationStatus: 'pending',
              );

          final String formattedStartTime = DateFormat.yMMMd().add_jm().format(currentAlert.createdAt);
          final bool isLiveTrackingActive = controllerState.isLiveLocationActive || currentAlert.liveLocationEnabled;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: currentAlert.status == 'active' ? AppColors.primary : Colors.green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        currentAlert.status == 'active'
                            ? Icons.warning_rounded
                            : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentAlert.status == 'active'
                                  ? 'SOS BROADCAST ACTIVE'
                                  : 'SOS RESOLVED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Elapsed Time: ${_formatDuration(_elapsedDuration)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Live Location Control Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.share_location_rounded, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Live Location Sharing',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: isLiveTrackingActive,
                              activeColor: AppColors.primary,
                              onChanged: (enabled) {
                                if (enabled) {
                                  ref
                                      .read(sosControllerProvider.notifier)
                                      .startLiveLocationTracking(widget.alertId);
                                } else {
                                  ref
                                      .read(sosControllerProvider.notifier)
                                      .stopLiveLocationTracking(widget.alertId);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLiveTrackingActive
                              ? 'Location updates stream to Firestore every 30 seconds while the app is open in the foreground.'
                              : 'Live location updates are currently paused. Toggle on to share real-time position updates.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (isLiveTrackingActive) ...[
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.circle, color: Colors.green, size: 12),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controllerState.lastLocationUpdate != null
                                      ? 'Location updated ${DateFormat.jm().format(controllerState.lastLocationUpdate!)} (${controllerState.lastLocationAccuracy?.toStringAsFixed(0) ?? 'N/A'}m accuracy)'
                                      : 'Acquiring live position stream...',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (kDebugMode && currentAlert.latitude != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Debug Coordinates: ${currentAlert.latitude!.toStringAsFixed(5)}, ${currentAlert.longitude!.toStringAsFixed(5)}',
                              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Privacy Notice Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.privacy_tip_outlined, color: AppColors.accent, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Privacy Notice: Live location sharing is active ONLY during this SOS session while the app is open in the foreground. Tracking stops automatically when SOS is resolved or after 30 minutes.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                            height: 1.3,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Alert Details Summary Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alert Session Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'Created At',
                          value: formattedStartTime,
                        ),
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          icon: Icons.timer_outlined,
                          label: 'Auto-Expires',
                          value: DateFormat.jm().format(currentAlert.expiresAt),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Direct Regional Emergency Call Button
                OutlinedButton.icon(
                  onPressed: _makeDirectEmergencyCall,
                  icon: const Icon(Icons.phone_forwarded_rounded, color: AppColors.primary),
                  label: Text(
                    'CALL EMERGENCY (${AppConfig.defaultEmergencyNumber})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),

                // Stop SOS Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isStopping ? null : () => _confirmStopSos(context),
                    icon: _isStopping
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.stop_circle_rounded, size: 28),
                    label: Text(
                      _isStopping ? 'STOPPING SOS...' : 'STOP SOS BROADCAST',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        letterSpacing: 1.1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to load alert details: $err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
