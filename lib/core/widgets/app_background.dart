import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Full-screen animated "aurora" background.
///
/// A deep indigo base with slowly drifting violet/fuchsia/teal glow blobs and
/// rising gold particle dust. Pure CustomPainter — no assets, no blur filter,
/// so it stays cheap on low-end devices.
class AppBackground extends StatefulWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A16),
                Color(0xFF08071A),
                Color(0xFF0A0616),
              ],
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) =>
                CustomPaint(painter: _AuroraPainter(_controller.value)),
          ),
        ),
        // Subtle vignette to keep the centre readable.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.4,
              colors: [Color(0x00000000), Color(0x66000000)],
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Blob {
  final Color color;
  final double opacity;
  const _Blob(this.color, this.opacity);
}

class _AuroraPainter extends CustomPainter {
  final double t;

  _AuroraPainter(this.t);

  static const List<_Blob> _blobs = [
    _Blob(Color(0xFF8B5CF6), 0.30), // violet
    _Blob(Color(0xFFEC4899), 0.22), // fuchsia
    _Blob(Color(0xFF2DD4BF), 0.16), // teal
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final twoPi = math.pi * 2;

    // Aurora glow blobs
    for (var i = 0; i < _blobs.length; i++) {
      final b = _blobs[i];
      final phase = t * twoPi + i * (twoPi / _blobs.length);
      final cx = w * (0.5 + 0.42 * math.sin(phase));
      final cy = h * (0.5 + 0.38 * math.sin(phase * 0.8 + i * 1.7));
      final radius =
          math.max(w, h) * (0.42 + 0.10 * math.sin(phase * 1.2 + i));
      final shader = RadialGradient(
        colors: [
          b.color.withValues(alpha: b.opacity),
          b.color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
      canvas.drawCircle(Offset(cx, cy), radius, Paint()..shader = shader);
    }

    // Rising particle dust
    for (var i = 0; i < 42; i++) {
      final speed = 0.05 + (i % 6) * 0.02;
      final py = h + 24 - (((t * speed + (i % 17) / 17.0) % 1.0) * (h + 48));
      final px = w * (((i * 97) % 100) / 100.0) +
          8 * math.sin(t * twoPi * 0.5 + i);
      final r = 0.8 + (i % 3) * 0.6;
      final alpha = 0.10 + 0.25 * ((i % 5) / 5.0);
      final color = i % 4 == 0
          ? const Color(0xFFFBBF24)
          : (i % 4 == 1 ? const Color(0xFF2DD4BF) : const Color(0xFFFFFFFF));
      canvas.drawCircle(
        Offset(px, py),
        r,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.t != t;
}
