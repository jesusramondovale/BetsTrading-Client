import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Helper para usar Google Fonts de forma segura, manejando errores de AssetManifest
class SafeFonts {
  /// Obtiene Syncopate con fallback a fuente del sistema
  static TextStyle syncopate({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    try {
      return GoogleFonts.syncopate(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (e) {
      // Si falla, usar fuente del sistema como fallback
      debugPrint('Error cargando Syncopate, usando fallback: $e');
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }

  /// Obtiene Montserrat con fallback a fuente del sistema
  static TextStyle montserrat({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    try {
      return GoogleFonts.montserrat(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (e) {
      // Si falla, usar fuente del sistema como fallback
      debugPrint('Error cargando Montserrat, usando fallback: $e');
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }

  /// Obtiene Lato con fallback a fuente del sistema
  static TextStyle lato({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    try {
      return GoogleFonts.lato(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (e) {
      // Si falla, usar fuente del sistema como fallback
      debugPrint('Error cargando Lato, usando fallback: $e');
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }
}

