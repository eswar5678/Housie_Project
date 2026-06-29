import 'dart:math';
import 'package:flutter/material.dart';

class StarLoader extends StatefulWidget {
  final double size;
  final Color color;

  const StarLoader({
    super.key,
    this.size = 80.0,
    this.color = Colors.amber,
  });

  @override
  State<StarLoader> createState() => _StarLoaderState();
}

class _StarLoaderState extends State<StarLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: StarPainter(
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class StarPainter extends CustomPainter {
  final double progress;
  final Color color;

  StarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _createStarPath(size);
    
    // Animate the drawing of the path
    final pathMetrics = path.computeMetrics();
    final drawingPath = Path();

    for (var metric in pathMetrics) {
      final extractPath = metric.extractPath(0, metric.length * progress);
      drawingPath.addPath(extractPath, Offset.zero);
    }

    canvas.drawPath(drawingPath, paint);
  }

  Path _createStarPath(Size size) {
    final path = Path();
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double outerRadius = size.width / 2;
    final double innerRadius = outerRadius * 0.4;
    const int points = 5;

    final double step = pi / points;
    
    // Start from the top point
    path.moveTo(centerX, centerY - outerRadius);

    for (int i = 1; i <= points * 2; i++) {
        final double radius = i.isEven ? outerRadius : innerRadius;
        final double angle = -pi / 2 + i * step;
        path.lineTo(
            centerX + radius * cos(angle),
            centerY + radius * sin(angle),
        );
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant StarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
