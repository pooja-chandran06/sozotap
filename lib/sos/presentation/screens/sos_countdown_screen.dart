import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../providers/sos_providers.dart';

class SosCountdownScreen extends ConsumerStatefulWidget {
  const SosCountdownScreen({super.key});

  @override
  ConsumerState<SosCountdownScreen> createState() => _SosCountdownScreenState();
}

class _SosCountdownScreenState extends ConsumerState<SosCountdownScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure countdown begins on screen load if not already started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(sosControllerProvider);
      if (!state.isCountingDown && !state.isActivating && state.activeAlertId == null) {
        ref.read(sosControllerProvider.notifier).startCountdown();
      }
    });
  }

  void _handleCancel() {
    ref.read(sosControllerProvider.notifier).cancelCountdown();
    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosControllerProvider);

    // Listen for activation completion to navigate to active SOS screen
    ref.listen(sosControllerProvider, (previous, next) {
      if (next.activeAlertId != null && next.activeAlertId != previous?.activeAlertId) {
        if (mounted) {
          context.go('/sos-active/${next.activeAlertId}');
        }
      }

      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red.shade900,
            ),
          );
        }
      }
    });

    final double progress = sosState.countdownSeconds / 5.0;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleCancel();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0000), // Dark red emergency theme
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'EMERGENCY SOS INITIATED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.2,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hold tight! Preparing to broadcast your emergency profile and location.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sosState.isActivating) ...[
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          const Text(
                            'Activating...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ] else ...[
                          Text(
                            '${sosState.countdownSeconds}',
                            style: const TextStyle(
                              fontSize: 84,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const Text(
                            'SECONDS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white60,
                              letterSpacing: 2,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Tap Cancel immediately if this was triggered accidentally.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: sosState.isActivating ? null : _handleCancel,
                        icon: const Icon(Icons.close_rounded, size: 28),
                        label: const Text(
                          'CANCEL SOS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
