import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

/// Superficies, tipografía y piezas comunes del rediseño (home / exchange).
///
/// Los colores dependen del tema activo; los getters que reciben `context`
/// llaman a `Theme.of` para que el widget se reconstruya al cambiar de tema.
abstract final class AppUi {
  static bool _dark(BuildContext context) {
    Theme.of(context);
    return AppTheme.pureBlack.value;
  }

  static Color surface(BuildContext context) => _dark(context)
      ? AppTheme.blackSurface
      : Colors.white.withValues(alpha: 0.07);

  static Color surfaceHigh(BuildContext context) => _dark(context)
      ? AppTheme.blackSurfaceHigh
      : Colors.white.withValues(alpha: 0.12);

  static Color border(BuildContext context) => _dark(context)
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.10);

  static Color accent(BuildContext context) =>
      _dark(context) ? AppTheme.blackAccent : const Color(0xFF22D3EE);

  static const Color gain = Color(0xFF22C55E);
  static const Color loss = Color(0xFFEF4444);

  static const double radius = 20;

  static TextStyle title({double size = 17, Color color = Colors.white}) =>
      GoogleFonts.montserrat(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = Colors.white,
  }) =>
      GoogleFonts.montserrat(fontSize: size, fontWeight: weight, color: color);

  static TextStyle number({double size = 40, Color color = Colors.white}) =>
      GoogleFonts.montserrat(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      );
}

/// Cabecera de sección: título semibold a la izquierda, sin divisor.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.leadingIcon,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(4, 12, 4, 4),
  });

  final String title;
  final Widget? leadingIcon;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(title, style: AppUi.title()),
          if (leadingIcon != null) ...[
            const SizedBox(width: 8),
            leadingIcon!,
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Botón circular con superficie, como los de la esquina superior del diseño.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 22,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppUi.surface(context),
      shape: CircleBorder(side: BorderSide(color: AppUi.border(context))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: IconTheme.merge(
              data: IconThemeData(size: iconSize, color: Colors.white),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

/// Píldora de variación diaria (verde / roja con fondo suave).
class GainPill extends StatelessWidget {
  const GainPill({super.key, required this.gain, this.fontSize = 12});

  final double gain;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final up = gain >= 0;
    final color = up ? AppUi.gain : AppUi.loss;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${up ? '+' : '−'}${gain.abs().toStringAsFixed(2)}%',
        style: AppUi.body(size: fontSize, weight: FontWeight.w700, color: color),
      ),
    );
  }
}
