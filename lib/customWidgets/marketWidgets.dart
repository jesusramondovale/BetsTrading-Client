import 'package:flutter/material.dart';

class GridWidget extends StatelessWidget {
  final double gridLineSpacing;
  final Color gridLineColor;

  const GridWidget({
    super.key,
    this.gridLineSpacing = 20.0,
    this.gridLineColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(gridLineSpacing: gridLineSpacing, gridLineColor: gridLineColor),
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridLineSpacing;
  final Color gridLineColor;
  final double lineWidth;

  GridPainter({
    required this.gridLineSpacing,
    required this.gridLineColor,
    this.lineWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = gridLineColor
      ..strokeWidth = lineWidth;

    for (double i = 0; i < size.width; i += gridLineSpacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += gridLineSpacing) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
