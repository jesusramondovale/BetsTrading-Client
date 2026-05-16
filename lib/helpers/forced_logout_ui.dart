import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../app_navigator.dart';
import '../locale/localized_texts.dart';
import '../ui/login_page.dart';

String maintenanceLogoutMessage() {
  final ctx = navigatorKey.currentContext;
  final strings = ctx != null ? LocalizedStrings.of(ctx) : null;
  final localized = strings?.get('maintenanceLogout');
  if (localized != null && localized.isNotEmpty) return localized;

  final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  switch (lang) {
    case 'es':
      return 'Servidores en mantenimiento. Disculpe las molestias.';
    case 'fr':
      return 'Serveurs en maintenance. Veuillez nous excuser pour la gêne occasionnée.';
    case 'it':
      return 'Server in manutenzione. Ci scusiamo per il disagio.';
    case 'de':
      return 'Server in Wartung. Entschuldigen Sie die Unannehmlichkeiten.';
    default:
      return 'Servers under maintenance. Sorry for the inconvenience.';
  }
}

String sessionStartedElsewhereMessage() {
  final ctx = navigatorKey.currentContext;
  final strings = ctx != null ? LocalizedStrings.of(ctx) : null;
  final localized = strings?.get('sessionStartedElsewhere');
  if (localized != null && localized.isNotEmpty) return localized;

  final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  switch (lang) {
    case 'es':
      return 'Sesión iniciada en otro dispositivo';
    case 'fr':
      return 'Session ouverte sur un autre appareil';
    case 'it':
      return 'Sessione avviata su un altro dispositivo';
    case 'de':
      return 'Sitzung auf einem anderen Gerät gestartet';
    default:
      return 'Session started on another device';
  }
}

void showOverlayNotification(
  String message,
  String ip,
  String city,
  String country, {
  bool showLocation = true,
}) {
  final overlayState = navigatorKey.currentState?.overlay;
  if (overlayState == null) return;

  late OverlayEntry overlayEntry;
  double opacity = 1.0;
  final locationSuffix = showLocation &&
          (city.isNotEmpty || country.isNotEmpty) &&
          city != 'Unknown city' &&
          country != 'Unknown country'
      ? '\n ($city, $country)'
      : '';

  overlayEntry = OverlayEntry(
    builder: (context) {
      return Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: StatefulBuilder(
          builder: (context, setState) {
            return AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 500),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$message$locationSuffix',
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );

  overlayState.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 4), () {
    opacity = 0.0;
    overlayEntry.markNeedsBuild();

    Future.delayed(const Duration(milliseconds: 500), () {
      overlayEntry.remove();
    });
  });
}

void showMaintenanceLogoutFromAccessLock() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showOverlayNotification(
      maintenanceLogoutMessage(),
      '',
      '',
      '',
      showLocation: false,
    );
    LoginPage.navigateToLogin(null);
  });
}

Future<void> handleForcedLogoutFirebaseMessage(RemoteMessage message) async {
  final type = message.data['type'];
  if (type != 'LOGOUT') return;

  final isMaintenance = message.data['reason'] == 'MAINTENANCE';
  final ip = message.data['ip'] ?? 'Unknown IP';
  final city = message.data['city'] ?? 'Unknown city';
  final country = message.data['country'] ?? 'Unknown country';

  const storage = FlutterSecureStorage();
  await storage.deleteAll();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isMaintenance) {
      showOverlayNotification(
        maintenanceLogoutMessage(),
        '',
        '',
        '',
        showLocation: false,
      );
    } else {
      showOverlayNotification(
        sessionStartedElsewhereMessage(),
        ip,
        city,
        country,
      );
    }
    LoginPage.navigateToLogin(null);
  });
}
