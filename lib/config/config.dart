import 'package:flutter/foundation.dart';

class Config {
  static const String publicDomain = 'api.betstrading.online';
  static const String landingPage = 'https://betstrading.online';
  static const String statusPage = 'https://api.betstrading.online/status';

  /// Misma origin cuando la web se sirve desde el API (localhost o api.betstrading.online).
  static String get apiBaseUrl {
    if (kIsWeb) {
      final base = Uri.base;
      final host = base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return '${base.scheme}://$host:${base.port}';
      }
      if (host == publicDomain) {
        return '${base.scheme}://$host';
      }
    }
    return 'https://$publicDomain';
  }

  static Uri apiUri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$normalized');
  }

  static const String instagramPage = 'https://www.instagram.com/betstrading/';
  static const String stripePublicRealKey = 'pk_live_51Ro4wQIXoMzVIHug9YI9hVDENlIIGqUIGIsIPapb4GHnAwtf7Vr3TxbfUHKRnk6sQk2tYTj963a5NWAICZD9XFFD00caAloHeS'; //REAL

  static const String termsNConditionsPage = 'https://raw.githubusercontent.com/jesusramondovale/BetsTrading-Client/refs/heads/android-master/policies/privacy_policy_en.md';
  static const String codeVersion = '26.291.1';
  static const String admobAppId = 'ca-app-pub-2465898294053562/1629478765';
  static const String admobAdToken = 'ca-app-pub-2465898294053562/4804536511'; // REAL
  /// Intersticial obligatorio (apuestas / umbral API / daily reward).
  static const String admobInterstitialMandatoryId = 'ca-app-pub-2465898294053562/3036757295';
  static const String ipGeolocalizerToken = 'd99daa2befa6f8';
  static const String serverCertificateHash = 'E475D88044C231E073B0B4F40B124D496FF01B0D0A964A26D458BFA9BC2BF249';
  /// Client ID Android / server (aud móvil).
  static const String serverClientId = '1020559524014-ge0t5b3bhkpdpg8h958b4rf8o716l12r.apps.googleusercontent.com';
  /// Client ID web OAuth (aud del idToken en Flutter Web).
  static const String googleWebClientId = '1020559524014-nj03cpc6e2941ugkisaetac8dg8gr204.apps.googleusercontent.com';

  // DEV
  static const double priceSimulation = 200.0;

  //TODO -> Values to be fetched from backend
  static const int priceBetPrize = 100000;
  static const int topUsersCount = 10;
  static const List<String> top10Rewards = [
    r'+2.000', r'+1.300', r'+1.000', r'+650', r'+400',
    r'+300', r'+200', r'+150', r'+100', r'+50',
  ];
}