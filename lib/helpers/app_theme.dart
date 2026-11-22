import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common.dart';

/// Gestiona el tema de la app.
///
/// - Tema "azul" (por defecto): el oscuro original (fondo navy + rejilla).
/// - Tema "negro": negro puro con superficies gris oscuro y acento violeta,
///   como el diseño de referencia del blackjack.
abstract final class AppTheme {
  static const String _prefKey = 'pureBlackTheme';

  /// `true` cuando está activo el tema negro.
  static final ValueNotifier<bool> pureBlack = ValueNotifier<bool>(false);

  // Paleta del tema negro.
  static const Color blackBackground = Color(0xFF000000);
  static const Color blackSurface = Color(0xFF1C1C1E);
  static const Color blackSurfaceHigh = Color(0xFF2A2A2C);
  static const Color blackAccent = Color(0xFF9B8CFF);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      pureBlack.value = prefs.getBool(_prefKey) ?? false;
    } catch (e) {
      debugPrint('AppTheme.load error: $e');
    }
  }

  static Future<void> setPureBlack(bool value) async {
    if (pureBlack.value == value) return;
    pureBlack.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (e) {
      debugPrint('AppTheme.setPureBlack error: $e');
    }
  }

  static Future<void> toggle() => setPureBlack(!pureBlack.value);

  static ThemeData themeFor(bool pureBlackEnabled) =>
      pureBlackEnabled ? _blackTheme : Common().themeDark;

  static final ThemeData _blackTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: blackAccent,
      secondary: blackAccent,
      surface: blackBackground,
      onSurface: Colors.white,
      surfaceContainer: blackSurface,
      surfaceContainerHighest: blackSurfaceHigh,
    ),
    scaffoldBackgroundColor: blackBackground,
    canvasColor: blackBackground,
    cardColor: blackSurface,
    dividerColor: Colors.white12,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: blackSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 440),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: blackSurface,
      constraints: BoxConstraints(maxWidth: 560),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return blackAccent;
        }
        return Colors.black;
      }),
      trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return blackAccent.withValues(alpha: 0.45);
        }
        return blackSurfaceHigh;
      }),
    ),
  );
}
