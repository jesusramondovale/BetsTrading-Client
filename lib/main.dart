import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/services/FirebaseService.dart';
import 'package:betrader/ui/consent_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'helpers/common.dart';
import 'ui/login_page.dart';
import 'ui/layout_page.dart';
import 'services/AuthService.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:betrader/Services/BetsService.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<String> getFirebaseInstanceId() async {
  // Get the instance of Firebase Messaging
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Get the token
  String? token = await messaging.getToken();

  // If the token is null, try again
  if (token == null) {
    token = await messaging.getToken();
  }

  return token!;
}

void showOverlayNotification(String message, String ip, String city, String country) {
  final overlayState = navigatorKey.currentState?.overlay;
  if (overlayState == null) return;

  late OverlayEntry overlayEntry;
  double opacity = 1.0;

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
                    "${message} \n (${city}, ${country})",
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
    overlayEntry.markNeedsBuild(); // fuerza rebuild con la nueva opacidad

    Future.delayed(const Duration(milliseconds: 500), () {
      overlayEntry.remove();
    });
  });
}


Future<void> handleFirebaseMessage(RemoteMessage message) async {

  final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  // This cannot be localized as string because here there's no context yet
  var notificationText = '';
  switch (lang) {
    case 'en':
      notificationText = 'Session started on another device';
    case 'es':
      notificationText = 'Sesión iniciada en otro dispositivo';
    case 'fr':
      notificationText = 'Session ouverte sur un autre appareil';
    case 'it':
      notificationText = 'Sessione avviata su un altro dispositivo';
    case 'de':
      notificationText = 'Sitzung auf einem anderen Gerät gestartet';
    default:
      notificationText = 'Session started on another device';
  }

  final type = message.data['type'];
  final ip = message.data['ip'] ?? "Unknown IP";
  final city = message.data['city'] ?? "Unknown city";
  final country = message.data['country'] ?? "Unknown country";

  if (type == 'LOGOUT') {
    final storage = FlutterSecureStorage();
    await storage.deleteAll();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showOverlayNotification(notificationText, ip, city, country);

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    });
  }
}




Future onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  // Handle the local notification received on iOS
}


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa los datos de localización para fechas y otros formatos
  await initializeDateFormatting();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {

  }
  await FirebaseService().initFirebase();

  FirebaseMessaging.onMessage.listen((message) {
    handleFirebaseMessage(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    handleFirebaseMessage(message);
  });

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

  stripe.Stripe.publishableKey = 'pk_test_51Ro4wcIoWhLn7aPbiJW4oRV3Gtvyijmw9hSGkn7pVMcOYZ4wpKmjRX1SA4tDPlJa8iKS1iRD5edE894KWgrRkqnM007ZLfNfKr';

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
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
        Locale('fr', ''),
        Locale('it', ''),
        Locale('de', ''),
      ],
      localizationsDelegates: const [
        LocalizedStringsDelegate(), // Soporte para LocalizedStrings
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
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    await ConsentPage.showConsentDialog(context);
    _checkAuthentication();
  }

  void _checkAuthentication() async {
    bool isLoggedIn = await AuthService().isLoggedIn();
    if (isLoggedIn) {
      String? id = await _storage.read(key: 'sessionToken');
      await BetsService().getUserInfo(id!);
      _navigateToHome();
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainMenuPage()),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
