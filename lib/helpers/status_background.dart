import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Colores del fondo de `/status` (StatusPage.html).
///
/// Con el tema negro activo ([AppTheme.pureBlack]) todos los tonos pasan a
/// negro puro y la rejilla desaparece.
abstract final class StatusBackgroundColors {
  static bool get _black => AppTheme.pureBlack.value;

  static Color get top => _black ? AppTheme.blackBackground : const Color(0xFF0F0F23);
  static Color get mid => _black ? AppTheme.blackBackground : const Color(0xFF1A1A2E);
  static Color get bottom => _black ? AppTheme.blackBackground : const Color(0xFF16213E);
  static Color get gridLine =>
      _black ? Colors.transparent : const Color(0x0822D3EE); // cyan ~3% alpha
}

/// Gradiente + rejilla idénticos a la página `/status` del API.
class StatusBackground extends StatelessWidget {
  const StatusBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.pureBlack,
      builder: (context, pureBlack, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    StatusBackgroundColors.top,
                    StatusBackgroundColors.mid,
                    StatusBackgroundColors.bottom,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            if (!pureBlack) const CustomPaint(painter: _StatusGridPainter()),
            if (child != null) child!,
          ],
        );
      },
    );
  }
}

/// Sustituye el antiguo splash+blur como fondo de páginas secundarias.
class StatusPageScaffoldBody extends StatelessWidget {
  const StatusPageScaffoldBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: StatusBackground()),
        child,
      ],
    );
  }
}

class _StatusGridPainter extends CustomPainter {
  const _StatusGridPainter();

  static const double _cell = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = StatusBackgroundColors.gridLine
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
