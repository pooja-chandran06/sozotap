import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../authentication/presentation/providers/auth_provider.dart';
import '../../sos/presentation/widgets/sos_button_widget.dart';
import '../../notifications/presentation/widgets/notification_badge_widget.dart';
import '../../qr/presentation/widgets/qr_dashboard_card_widget.dart';
import '../../settings/presentation/providers/settings_providers.dart';
import '../../core/widgets/offline_banner_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    final isOfflineAsync = ref.watch(isOfflineProvider);
    final isOffline = isOfflineAsync.value ?? false;
    final repository = ref.read(settingsRepositoryProvider);
    final lastSyncedAt = repository.getLastSyncedAt();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SOZOTAP Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          const NotificationBadgeWidget(),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'App Settings',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineBannerWidget(
            isOffline: isOffline,
            lastSyncedAt: lastSyncedAt,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome, ${user?.email ?? "User"}!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'One Tap Can Save a Life.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Prominent SOS Button
                  const SosButtonWidget(size: 160),
                  
                  const SizedBox(height: 28),

                  // Emergency Medical QR Card
                  const QrDashboardCardWidget(),

                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () => context.push('/emergency-contacts'),
                    icon: const Icon(Icons.contacts_rounded),
                    label: const Text('Emergency Contacts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
