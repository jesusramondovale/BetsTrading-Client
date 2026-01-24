import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bets.dart';
import '../models/favorites.dart';
import '../models/trends.dart';
import '../services/bets_service.dart';

/// Cache estático de datos precargados durante la pantalla "Cargando..."
///
/// Permite cargar profile pic, trends, favorites e investments antes de navegar
/// a MainMenuPage, para que la pantalla de Cargando no se abandone hasta que
/// todo esté listo.
class PreloadCache {
  static Uint8List? _profilePicBytes;
  static Trends? _trends;
  static Favorites? _favorites;
  static BetsAndPriceBets? _investmentData;

  static Uint8List? get profilePicBytes => _profilePicBytes;
  static Trends? get trends => _trends;
  static Favorites? get favorites => _favorites;
  static BetsAndPriceBets? get investmentData => _investmentData;

  static bool get hasProfilePic => _profilePicBytes != null;
  static bool get hasHomeData =>
      _trends != null && _favorites != null && _investmentData != null;

  static void setProfilePic(Uint8List? bytes) {
    _profilePicBytes = bytes;
  }

  static void setHomeData({
    Trends? trends,
    Favorites? favorites,
    BetsAndPriceBets? investment,
  }) {
    _trends = trends;
    _favorites = favorites;
    _investmentData = investment;
  }

  /// Consume y elimina la foto de perfil precargada.
  static Uint8List? takeProfilePic() {
    final v = _profilePicBytes;
    _profilePicBytes = null;
    return v;
  }

  /// Consume y elimina los datos de Home precargados.
  static (Trends?, Favorites?, BetsAndPriceBets?) takeHomeData() {
    final t = _trends;
    final f = _favorites;
    final i = _investmentData;
    _trends = null;
    _favorites = null;
    _investmentData = null;
    return (t, f, i);
  }

  static void clear() {
    _profilePicBytes = null;
    _trends = null;
    _favorites = null;
    _investmentData = null;
  }

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Precarga la foto de perfil: lee de storage (base64 o URL) y, si es URL, la descarga.
  static Future<void> preloadProfilePic() async {
    try {
      final profilePicString = await _storage.read(key: 'profilepic');
      if (profilePicString == null ||
          profilePicString.isEmpty ||
          profilePicString == 'null' ||
          profilePicString.toLowerCase() == 'null') {
        return;
      }
      Uint8List imageBytes;
      if (profilePicString.startsWith('http')) {
        final response = await http.get(Uri.parse(profilePicString));
        if (response.statusCode != 200) {
          if (kDebugMode) {
            // ignore: avoid_print
            print('[PreloadCache] Error loading profile pic from URL: ${response.statusCode}');
          }
          return;
        }
        imageBytes = response.bodyBytes;
      } else {
        try {
          imageBytes = base64Decode(profilePicString);
        } catch (e) {
          if (kDebugMode) {
            // ignore: avoid_print
            print('[PreloadCache] Error decoding base64 profile pic: $e');
          }
          return;
        }
      }
      _profilePicBytes = imageBytes;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[PreloadCache] Error preloading profile pic: $e');
      }
    }
  }

  /// Precarga trends, favorites e investment data para Home.
  static Future<void> preloadHomeData() async {
    try {
      final userId = await _storage.read(key: 'sessionToken') ?? 'none';
      final prefs = await SharedPreferences.getInstance();
      final dollarCurrency = prefs.getBool('dollarCurrency') ?? false;
      final currency = dollarCurrency ? 'USD' : 'EUR';

      final trends = await BetsService().fetchTrendsData(userId, currency);
      final favorites = await BetsService().fetchFavouritesData(userId, currency);
      final investment = await BetsService().fetchInvestmentData(userId, currency);

      setHomeData(trends: trends, favorites: favorites, investment: investment);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[PreloadCache] Error preloading home data: $e');
      }
    }
  }

  /// Ejecuta todas las precargas necesarias antes de ir a MainMenuPage.
  static Future<void> preloadAll() async {
    await Future.wait([
      preloadProfilePic(),
      preloadHomeData(),
    ]);
  }
}
