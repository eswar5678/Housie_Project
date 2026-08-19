import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable glassmorphic surface panel used across the landscape screens.
///
/// Provides a consistent background, border, radius and an optional header
/// row (title + trailing widget) so every feature panel looks identical.
class AppPanel extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool scrollable;

  const AppPanel({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(AppDimens.lg),
    this.radius = AppDimens.radiusXl,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || trailing != null;

    Widget content = hasHeader
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.md),
                child: Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
              child,
            ],
          )
        : child;

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
      ),
      child: content,
    );
  }
}
