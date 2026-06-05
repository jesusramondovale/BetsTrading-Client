import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/services/firebase_service.dart';
import 'package:betrader/ui/consent_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'config/config.dart';
import 'app_navigator.dart';
import 'local_notifications.dart';
import 'helpers/common.dart';
import 'helpers/forced_logout_ui.dart';
import 'ui/login_page.dart';
import 'services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:betrader/services/bets_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'dart:async';

// Helper para configurar Google Fonts
// Con la versión 6.3.3+, el paquete maneja automáticamente la falta de AssetManifest.json
Future<void> _configureGoogleFonts() async {
  try {
    // Habilitar descarga de fuentes en tiempo de ejecución
    // Esto permite que las fuentes se descarguen desde internet si el AssetManifest no está disponible
    GoogleFonts.config.allowRuntimeFetching = true;
    debugPrint('Google Fonts configurado para descarga en tiempo de ejecución');
  } catch (e) {
    // Si hay un error al configurar, continuar de todas formas
    debugPrint('Advertencia: Error al configurar Google Fonts: $e');
  }
}

Future<String> getFirebaseInstanceId() async {
  // Get the instance of Firebase Messaging
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Get the token
  String? token = await messaging.getToken();

  // If the token is null, try again
  token ??= await messaging.getToken();

  return token!;
}

Future onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  // Handle the local notification received on iOS
}

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting();

  // Configurar Google Fonts para evitar errores con AssetManifest.json
  // La versión 6.3.3+ maneja automáticamente este problema
  _configureGoogleFonts();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  await FirebaseService().initFirebase();

  FirebaseMessaging.onMessage.listen(handleForcedLogoutFirebaseMessage);

  FirebaseMessaging.onMessageOpenedApp.listen(handleForcedLogoutFirebaseMessage);

  var initializationSettingsAndroid = AndroidInitializationSettings('@drawable/notification');
  var initializationSettingsDarwin = const DarwinInitializationSettings();

  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  MobileAds.instance.initialize();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  stripe.Stripe.publishableKey = Config.stripePublicRealKey;
  await stripe.Stripe.instance.applySettings();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: Common().themeDark,
      title: 'Betrader',
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
        Locale('fr', ''),
        Locale('it', ''),
        Locale('de', ''),
      ],
      localizationsDelegates: const [
        LocalizedStringsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    await ConsentPage.showConsentDialog(context);
    if (!mounted) return;
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    bool isLoggedIn = await AuthService().isLoggedIn();
    
    // Realizar las operaciones necesarias
    if (isLoggedIn) {
      String? id = await _storage.read(key: 'sessionToken');
      if (id != null && id.isNotEmpty && id != 'empty') {
        await BetsService().getUserInfo(id);
      }
    }
    
    // Precargar assets del LoginPage para evitar pantallazo negro
    if (!isLoggedIn) {
      await _preloadLoginAssets();
    }
    
    // Asegurar que el splash dure al menos 3 segundos
    final elapsed = DateTime.now().difference(_startTime!);
    final minDuration = const Duration(seconds: 3);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }
    
    // Navegar después de cumplir el tiempo mínimo
    if (isLoggedIn) {
      // Para auto-login, navegar al login primero para cargar datos
      _navigateToLoginForAutoLogin();
    } else {
      _navigateToLogin();
    }
  }

  Future<void> _preloadLoginAssets() async {
    try {
      // Precargar imágenes del LoginPage
      await Future.wait([
        precacheImage(const AssetImage('assets/android12splash-clean.png'), context),
        precacheImage(const AssetImage('assets/new_icon.png'), context),
        precacheImage(const AssetImage('assets/google.png'), context),
      ]);
    } catch (e) {
      // Si hay error al precargar, continuar de todas formas
      debugPrint('Advertencia: Error al precargar assets: $e');
    }
  }


  void _navigateToLogin() {
    if (mounted) {
      LoginPage.navigateToLogin(context);
    }
  }

  void _navigateToLoginForAutoLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage(isAutoLogin: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el código de idioma del contexto o del dispatcher
    final locale = Localizations.maybeLocaleOf(context) ?? 
                   WidgetsBinding.instance.platformDispatcher.locale;
    String languageCode = locale.languageCode;
    
    // Verificar que el idioma esté soportado (en, es, fr, it, de)
    const supportedLanguages = ['en', 'es', 'fr', 'it', 'de'];
    if (!supportedLanguages.contains(languageCode)) {
      languageCode = 'en'; // Fallback a inglés
    }
    
    // Construir la ruta del asset dinámicamente
    final splashAsset = 'assets/android12splash-$languageCode.png';
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(splashAsset),
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
