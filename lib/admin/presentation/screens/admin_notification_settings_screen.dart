import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../data/models/admin_notification_settings.dart';
import '../providers/admin_notification_settings_provider.dart';

class AdminNotificationSettingsScreen extends ConsumerStatefulWidget {
  const AdminNotificationSettingsScreen({super.key});

  @override
  ConsumerState<AdminNotificationSettingsScreen> createState() => _AdminNotificationSettingsScreenState();
}

class _AdminNotificationSettingsScreenState extends ConsumerState<AdminNotificationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _notifyOnTemplateChange = true;
  String _preferredChannel = 'email';
  final _emailOverrideController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _emailOverrideController.dispose();
    super.dispose();
  }

  void _syncState(AdminNotificationSettings settings) {
    if (!_initialized) {
      _notifyOnTemplateChange = settings.notifyOnTemplateChange;
      _preferredChannel = settings.preferredChannel;
      _emailOverrideController.text = settings.emailOverride ?? '';
      _initialized = true;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentSettings = ref.read(adminNotificationSettingsProvider).settings;
    if (currentSettings == null) return;

    final updated = currentSettings.copyWith(
      notifyOnTemplateChange: _notifyOnTemplateChange,
      preferredChannel: _preferredChannel,
      emailOverride: _emailOverrideController.text.trim().isEmpty ? null : _emailOverrideController.text.trim(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(adminNotificationSettingsProvider.notifier).saveSettings(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminNotificationSettingsProvider);

    if (state.isLoading && state.settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Preferences'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.settings != null) {
      _syncState(state.settings!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Change Alerts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure how you receive instant real-time alerts and daily digest reports when notification templates are created or updated.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                title: const Text('Notify on Template Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Receive real-time alerts when templates in your scope are updated.'),
                value: _notifyOnTemplateChange,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _notifyOnTemplateChange = val),
              ),
              const Divider(height: 32),

              const Text('Preferred Channel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              RadioListTile<String>(
                title: const Text('Email Only (SendGrid)'),
                subtitle: const Text('Receive rich HTML diff reports via email.'),
                value: 'email',
                groupValue: _preferredChannel,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _preferredChannel = val!),
              ),
              RadioListTile<String>(
                title: const Text('Slack Webhook'),
                subtitle: const Text('Receive alerts directly in the team Slack channel.'),
                value: 'slack',
                groupValue: _preferredChannel,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _preferredChannel = val!),
              ),
              RadioListTile<String>(
                title: const Text('Both (Email + Slack)'),
                subtitle: const Text('Receive alerts on both Email and Slack.'),
                value: 'both',
                groupValue: _preferredChannel,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _preferredChannel = val!),
              ),
              RadioListTile<String>(
                title: const Text('None'),
                subtitle: const Text('Disable alerts for template updates.'),
                value: 'none',
                groupValue: _preferredChannel,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _preferredChannel = val!),
              ),
              const Divider(height: 32),

              TextFormField(
                controller: _emailOverrideController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Notification Email Override (Optional)',
                  hintText: 'Leave blank to use your default Auth email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: state.isLoading ? null : _save,
                  icon: state.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: const Text('Save Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
