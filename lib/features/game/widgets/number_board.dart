import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Compact 1–90 number board. Called numbers light up gold with a glow; the
/// most recent number pulses.
class NumberBoard extends StatelessWidget {
  final List<int> calledNumbers;

  const NumberBoard({super.key, required this.calledNumbers});

  @override
  Widget build(BuildContext context) {
    final lastCalled = calledNumbers.isEmpty ? null : calledNumbers.last;

    return Container(
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
        ),
        itemCount: 90,
        itemBuilder: (context, index) {
          final number = index + 1;
          final isCalled = calledNumbers.contains(number);
          final isLast = number == lastCalled;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: isCalled ? AppColors.goldGradient : null,
              color: isCalled ? null : AppColors.surfaceHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppDimens.radiusXs + 1),
              border: Border.all(
                color: isCalled
                    ? AppColors.accent.withValues(alpha: 0.6)
                    : AppColors.border,
              ),
              boxShadow: isCalled
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: isLast ? 0.7 : 0.35),
                        blurRadius: isLast ? 12 : 6,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                color: isCalled ? AppColors.onAccent : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isCalled ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}
