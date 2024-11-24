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
import 'services/BetsService.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // Para inicializar las localizaciones
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa los datos de localización para fechas y otros formatos
  await initializeDateFormatting();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseService().initFirebase();

  bool isDark = await loadThemePreference();

  runApp(MyApp(isDarkTheme: isDark));
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
