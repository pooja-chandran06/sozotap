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
