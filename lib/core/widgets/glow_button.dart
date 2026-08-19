import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Premium gradient button with a soft colored glow and ripple feedback.
class GlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Gradient gradient;
  final Color glowColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const GlowButton({
    super.key,
    required this.label,
    required this.gradient,
    required this.glowColor,
    this.icon,
    this.onPressed,
    this.foregroundColor = Colors.white,
    this.height = 52,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd + 2),
          child: Ink(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd + 2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: enabled ? 0.45 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foregroundColor, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                      fontSize: fontSize,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
