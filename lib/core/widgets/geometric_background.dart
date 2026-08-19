import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';

enum BackgroundShape { circle, square, triangle, hexagon }

class GeometricBackground extends StatelessWidget {
  final List<BackgroundShapeItem> shapes;
  final Widget child;

  const GeometricBackground({
    super.key,
    required this.shapes,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Color
        Container(color: AppColors.background),
        
        // Abstract Shapes
        ...shapes.map((shape) => Positioned(
              top: shape.top,
              left: shape.left,
              right: shape.right,
              bottom: shape.bottom,
              child: Opacity(
                opacity: 0.2, // Peaceful, subtle opacity
                child: _buildShape(shape),
              ),
            )),
            
        // Main Content
        child,
      ],
    );
  }

  Widget _buildShape(BackgroundShapeItem item) {
    switch (item.shape) {
      case BackgroundShape.circle:
        return Container(
          width: item.size,
          height: item.size,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
          ),
        );
      case BackgroundShape.square:
        return Transform.rotate(
          angle: item.rotation,
          child: Container(
            width: item.size,
            height: item.size,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(item.size * 0.1),
            ),
          ),
        );
      case BackgroundShape.triangle:
        return Transform.rotate(
          angle: item.rotation,
          child: CustomPaint(
            size: Size(item.size, item.size),
            painter: _TrianglePainter(item.color),
          ),
        );
      case BackgroundShape.hexagon:
        return Transform.rotate(
          angle: item.rotation,
          child: CustomPaint(
            size: Size(item.size, item.size),
            painter: _HexagonPainter(item.color),
          ),
        );
    }
  }
}

class BackgroundShapeItem {
  final BackgroundShape shape;
  final Color color;
  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double rotation;

  BackgroundShapeItem({
    required this.shape,
    required this.color,
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.rotation = 0.0,
  });
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _HexagonPainter extends CustomPainter {
  final Color color;
  _HexagonPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final double radius = size.width / 2;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    for (int i = 0; i < 6; i++) {
      double angle = (math.pi / 3) * i;
      double x = centerX + radius * math.cos(angle);
      double y = centerY + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
