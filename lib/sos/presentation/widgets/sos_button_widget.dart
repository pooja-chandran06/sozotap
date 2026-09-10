import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../providers/sos_providers.dart';

class SosButtonWidget extends ConsumerWidget {
  final double size;
  final bool isCompact;

  const SosButtonWidget({
    super.key,
    this.size = 160.0,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isCompact) {
      return ElevatedButton.icon(
        onPressed: () {
          ref.read(sosControllerProvider.notifier).startCountdown();
          context.push('/sos');
        },
        icon: const Icon(Icons.warning_amber_rounded, size: 24),
        label: const Text(
          'EMERGENCY SOS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            fontFamily: 'Poppins',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      );
    }

    return Semantics(
      label: 'Emergency SOS Button',
      hint: 'Double tap to open 5 second emergency countdown',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(sosControllerProvider.notifier).startCountdown();
            context.push('/sos');
          },
          customBorder: const CircleBorder(),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 6,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.touch_app_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'ONE TAP HELP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
