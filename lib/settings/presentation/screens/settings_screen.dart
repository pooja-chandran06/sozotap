import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/settings_providers.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _launchUrlSafely(BuildContext context, String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch URL: $urlString')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching URL: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final repository = ref.watch(settingsRepositoryProvider);
    final hiveCacheService = ref.watch(hiveCacheServiceProvider);

    final lastSyncedAt = repository.getLastSyncedAt();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('SOZOTAP Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Preferences
          const Text('APPEARANCE & THEME', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.palette_outlined, color: Color(0xFF0A84FF)),
              title: const Text('Theme Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Current: ${currentThemeMode.name.toUpperCase()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: DropdownButton<ThemeMode>(
                dropdownColor: const Color(0xFF2C2C2E),
                value: currentThemeMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('System', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    themeNotifier.setThemeMode(val);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text('PRIVACY & SECURITY', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          _buildTile(
            icon: Icons.security_rounded,
            color: const Color(0xFF0A84FF),
            title: 'Privacy & Emergency Sharing',
            subtitle: 'Manage public medical QR consent flags & sharing defaults',
            onTap: () => context.push('/settings/privacy'),
          ),

          _buildTile(
            icon: Icons.notifications_outlined,
            color: const Color(0xFF30D158),
            title: 'Notification Preferences',
            subtitle: 'Configure SOS push alerts, SMS fallback & reminders',
            onTap: () => context.push('/notification-settings'),
          ),

          _buildTile(
            icon: Icons.manage_accounts_rounded,
            color: const Color(0xFFFF9500),
            title: 'Account & Security Controls',
            subtitle: 'Edit profile, change password, or request account deletion',
            onTap: () => context.push('/account'),
          ),

          const SizedBox(height: 24),
          const Text('SYSTEM & LEGAL', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          _buildTile(
            icon: Icons.info_outline_rounded,
            color: const Color(0xFF64D2FF),
            title: 'About SOZOTAP',
            subtitle: 'Version info, tagline & legal acknowledgements',
            onTap: () => context.push('/settings/about'),
          ),

          _buildTile(
            icon: Icons.description_outlined,
            color: Colors.grey,
            title: 'Terms of Service',
            subtitle: 'Read official terms of service',
            onTap: () => _launchUrlSafely(context, 'https://vitanexus.web.app/terms.html'),
          ),

          _buildTile(
            icon: Icons.privacy_tip_outlined,
            color: Colors.grey,
            title: 'Privacy Policy',
            subtitle: 'Read official privacy policy',
            onTap: () => _launchUrlSafely(context, 'https://vitanexus.web.app/privacy.html'),
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.sync, color: Colors.grey, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Last synced: ${lastSyncedAt != null ? lastSyncedAt.toString().substring(0, 16) : "Never"}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF3B30)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1C1C1E),
                    title: const Text('Sign Out of SOZOTAP?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: const Text(
                      'Your local offline cache will be safely cleared. Cloud data will remain secure.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                  if (uid.isNotEmpty) {
                    await hiveCacheService.clearUserCache(uid);
                  }
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
              icon: const Icon(Icons.logout, color: Color(0xFFFF3B30)),
              label: const Text('Sign Out', style: TextStyle(color: Color(0xFFFF3B30), fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        onTap: onTap,
      ),
    );
  }
}
