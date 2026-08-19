import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Hero "current number" ring with an animated reveal and countdown arc.
class CurrentNumberRing extends StatelessWidget {
  final String displayNumber;
  final double progress; // 0..1
  final String countdownLabel;

  const CurrentNumberRing({
    super.key,
    required this.displayNumber,
    required this.progress,
    required this.countdownLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient glow behind the ring
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.fuchsia.withValues(alpha: 0.45),
                      blurRadius: 26,
                    ),
                  ],
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFDCE4F5)],
                  ),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Text(
                    displayNumber,
                    key: ValueKey(displayNumber),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 66,
                height: 66,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  color: AppColors.fuchsia,
                  backgroundColor: Colors.white24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.sm + 2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.fuchsia.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                border: Border.all(
                  color: AppColors.fuchsia.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.fuchsia,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                countdownLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
