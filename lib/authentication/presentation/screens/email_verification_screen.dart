import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';

class EmailVerificationScreen extends ConsumerWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread, color: AppColors.primary, size: 80),
              const SizedBox(height: 32),
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We have sent a verification email to your address. Please verify your email to access all features.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AuthButton(
                text: 'Resend Verification Email',
                onPressed: () {
                  ref.read(authControllerProvider.notifier).sendEmailVerification();
                },
                isLoading: isLoading,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).reloadUser();
                },
                child: const Text('I have verified my email', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
                child: const Text('Cancel & Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
