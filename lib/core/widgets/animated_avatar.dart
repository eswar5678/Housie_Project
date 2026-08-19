import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated player avatar with online glow, host star and presence dot.
///
/// Extracted from the game screen so it can be reused across features.
class AnimatedAvatar extends StatefulWidget {
  final String name;
  final bool isOnline;
  final bool isHost;
  final double size;

  const AnimatedAvatar({
    super.key,
    required this.name,
    required this.isOnline,
    required this.isHost,
    this.size = 50,
  });

  @override
  State<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<AnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColorFromName(String name) {
    final hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    const colors = [
      Colors.blueAccent,
      Colors.pinkAccent,
      Colors.tealAccent,
      Colors.amberAccent,
      Colors.purpleAccent,
      Colors.deepOrangeAccent,
      Colors.greenAccent,
      Colors.cyanAccent,
    ];
    return colors[hash % colors.length];
  }

  IconData _getIconFromName(String name) {
    final hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    const icons = [
      Icons.sports_esports,
      Icons.face,
      Icons.sentiment_very_satisfied,
      Icons.flash_on,
      Icons.star,
      Icons.palette,
      Icons.anchor,
      Icons.auto_awesome,
    ];
    return icons[hash % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getColorFromName(widget.name);
    final avatarIcon = _getIconFromName(widget.name);

    return SizedBox(
      width: widget.size + 10,
      height: widget.size + 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isOnline)
            RotationTransition(
              turns: _controller,
              child: Container(
                width: widget.size + 6,
                height: widget.size + 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      baseColor.withValues(alpha: 0.1),
                      baseColor,
                      baseColor.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.isOnline
                  ? AppColors.surfaceHigh
                  : Colors.grey.shade900,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isOnline ? Colors.white24 : Colors.white10,
                width: 2,
              ),
            ),
            child: Icon(
              avatarIcon,
              color: widget.isOnline ? baseColor : Colors.grey,
              size: widget.size * 0.5,
            ),
          ),
          if (widget.isHost)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, size: 10, color: Colors.black),
              ),
            ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.isOnline ? Colors.greenAccent : Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
