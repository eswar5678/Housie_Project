import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Compact 1–90 number board shown on the right side of the landscape
/// game layout. Called numbers light up in gold.
class NumberBoard extends StatelessWidget {
  final List<int> calledNumbers;

  const NumberBoard({super.key, required this.calledNumbers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
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
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isCalled
                  ? AppColors.accent
                  : AppColors.surfaceHigh.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppDimens.radiusXs),
              border: Border.all(
                color: isCalled ? AppColors.accent : AppColors.border,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                color: isCalled ? AppColors.onAccent : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isCalled ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}
