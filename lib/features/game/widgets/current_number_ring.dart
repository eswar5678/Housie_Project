import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// The live "current number" ring with a countdown progress arc.
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
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDCE4F0), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  displayNumber,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.background,
                  ),
                ),
              ),
              SizedBox(
                width: 62,
                height: 62,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  color: const Color(0xFFFF7043),
                  backgroundColor: Colors.white24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LIVE NUMBER',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                countdownLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
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
