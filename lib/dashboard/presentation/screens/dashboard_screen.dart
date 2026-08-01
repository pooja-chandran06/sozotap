import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../widgets/medical_card.dart';
import '../widgets/emergency_card.dart';
import '../widgets/qr_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOZOTAP', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Templates',
            onPressed: () => context.push('/admin/templates'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      user?.email.isNotEmpty == true ? user!.email[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hello & Stay Safe,', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(
                        user?.email ?? 'User',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // SOS Trigger Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'ONE TAP EMERGENCY SOS',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Dispatches multi-channel alerts to your saved emergency contacts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/emergency-contacts'),
                      icon: const Icon(Icons.touch_app),
                      label: const Text('TRIGGER SOS NOW', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Quick Action Cards Grid
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: const [
                  MedicalCard(),
                  EmergencyCard(),
                  QrCard(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
