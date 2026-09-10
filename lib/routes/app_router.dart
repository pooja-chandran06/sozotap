import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/splash/splash_screen.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../authentication/presentation/screens/login_screen.dart';
import '../authentication/presentation/screens/register_screen.dart';
import '../authentication/presentation/screens/forgot_password_screen.dart';
import '../presentation/dashboard/home_screen.dart';
import '../authentication/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../emergency_contacts/presentation/screens/emergency_contacts_screen.dart';
import '../emergency_contacts/presentation/screens/add_edit_contact_screen.dart';
import '../emergency_contacts/domain/models/emergency_contact.dart';
import '../sos/presentation/screens/sos_countdown_screen.dart';
import '../sos/presentation/screens/active_sos_screen.dart';
import '../sos/presentation/screens/sos_alert_detail_screen.dart';
import '../notifications/presentation/screens/notifications_screen.dart';
import '../notifications/presentation/screens/notification_settings_screen.dart';
import '../qr/presentation/screens/my_emergency_qr_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasCompletedOnboarding = ref.watch(onboardingProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/sos',
        builder: (context, state) => const SosCountdownScreen(),
      ),
      GoRoute(
        path: '/sos-active/:alertId',
        builder: (context, state) {
          final alertId = state.pathParameters['alertId'] ?? '';
          return ActiveSosScreen(alertId: alertId);
        },
      ),
      GoRoute(
        path: '/sos-alert/:alertId',
        builder: (context, state) {
          final alertId = state.pathParameters['alertId'] ?? '';
          return SosAlertDetailScreen(alertId: alertId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/my-emergency-qr',
        builder: (context, state) => const MyEmergencyQrScreen(),
      ),
      GoRoute(
        path: '/emergency-contacts',
        builder: (context, state) => const EmergencyContactsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddEditContactScreen(),
          ),
          GoRoute(
            path: 'add-edit',
            builder: (context, state) {
              final contact = state.extra as EmergencyContact?;
              return AddEditContactScreen(contact: contact);
            },
          ),
          GoRoute(
            path: ':contactId/edit',
            builder: (context, state) {
              final contact = state.extra as EmergencyContact?;
              return AddEditContactScreen(contact: contact);
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!hasCompletedOnboarding) {
        return isOnboarding ? null : '/onboarding';
      }

      return authState.when(
        data: (user) {
          if (user == null) {
            return isLoggingIn ? null : '/login';
          }

          if (isLoggingIn || isSplash || isOnboarding) {
            return '/';
          }

          return null;
        },
        loading: () => isSplash ? null : '/splash',
        error: (_, __) => isLoggingIn ? null : '/login',
      );
    },
  );
});
