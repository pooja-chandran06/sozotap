import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesStreamProvider);
    final tokensAsync = ref.watch(deviceTokensStreamProvider);
    final repository = ref.watch(notificationRepositoryProvider);
    final fcmService = ref.watch(fcmServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Notification Preferences', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: prefsAsync.when(
        data: (prefs) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Permission Request Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0A84FF).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: Color(0xFF0A84FF), size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Emergency Alerts',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ensure push notifications are granted so you never miss an SOS request.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final settings = await fcmService.requestPermission();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Permission status: ${settings.authorizationStatus.name}'),
                          ),
                        );
                      },
                      child: const Text('Grant', style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text('EMERGENCY DISPATCH SETTINGS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              _buildSwitchTile(
                title: 'SOS Push Notifications',
                subtitle: 'Receive instant high-priority alerts when contacts trigger an SOS.',
                value: prefs.sosPushEnabled,
                onChanged: (val) {
                  repository.updateNotificationPreferences(prefs.copyWith(sosPushEnabled: val));
                },
              ),

              _buildSwitchTile(
                title: 'SMS Alert Opt-In',
                subtitle: 'Allow emergency contacts to send SMS backup alerts to your number.',
                value: prefs.sosSmsEnabled,
                onChanged: (val) {
                  repository.updateNotificationPreferences(prefs.copyWith(sosSmsEnabled: val));
                },
              ),

              const SizedBox(height: 24),
              const Text('HEALTH & SYSTEM REMINDERS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              _buildSwitchTile(
                title: 'Medication Reminders',
                subtitle: 'Get notified for scheduled daily medication doses.',
                value: prefs.medicationReminderEnabled,
                onChanged: (val) {
                  repository.updateNotificationPreferences(prefs.copyWith(medicationReminderEnabled: val));
                },
              ),

              _buildSwitchTile(
                title: 'Appointment Reminders',
                subtitle: 'Notifications for upcoming medical consultations.',
                value: prefs.appointmentReminderEnabled,
                onChanged: (val) {
                  repository.updateNotificationPreferences(prefs.copyWith(appointmentReminderEnabled: val));
                },
              ),

              _buildSwitchTile(
                title: 'Medical QR Code Scan Alerts',
                subtitle: 'Alert me whenever my public medical QR card is scanned by a first responder.',
                value: prefs.qrScanAlertEnabled,
                onChanged: (val) {
                  repository.updateNotificationPreferences(prefs.copyWith(qrScanAlertEnabled: val));
                },
              ),

              const SizedBox(height: 24),
              const Text('REGISTERED DEVICES', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              tokensAsync.when(
                data: (tokens) {
                  if (tokens.isEmpty) {
                    return const Text('No devices registered.', style: TextStyle(color: Colors.grey));
                  }
                  return Column(
                    children: tokens.map((token) {
                      return ListTile(
                        leading: Icon(
                          token.platform == 'android'
                              ? Icons.android
                              : (token.platform == 'ios' ? Icons.phone_iphone : Icons.devices),
                          color: Colors.grey,
                        ),
                        title: Text(
                          '${token.platform.toUpperCase()} Token',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Permission: ${token.notificationPermissionStatus ?? "unknown"}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: Icon(
                          token.enabled ? Icons.check_circle : Icons.cancel,
                          color: token.enabled ? const Color(0xFF30D158) : Colors.red,
                          size: 18,
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0A84FF))),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        activeColor: const Color(0xFF0A84FF),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
