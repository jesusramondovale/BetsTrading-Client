import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/services/FirebaseService.dart';
import 'package:betrader/ui/consent_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

Future<void> main() async {



  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa los datos de localización para fechas y otros formatos
  await initializeDateFormatting();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseService().initFirebase();

  bool isDark = await loadThemePreference();
  var initializationSettingsAndroid = AndroidInitializationSettings('@drawable/notification');
  var initializationSettingsDarwin = DarwinInitializationSettings(
    onDidReceiveLocalNotification: onDidReceiveLocalNotification,
  );

  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  await FirebaseService().initFirebase();
  MobileAds.instance.initialize();
  runApp(MyApp(isDarkTheme: isDark));
}
Future onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  // Handle the local notification received on iOS
}

Future<bool> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('darkTheme') ?? true;
}

class MyApp extends StatelessWidget {
  final bool isDarkTheme;

  const MyApp({super.key, required this.isDarkTheme});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkTheme ? Common().themeDark : Common().themeLight,
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
