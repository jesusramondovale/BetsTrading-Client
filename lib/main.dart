import 'package:client_0_0_1/services/BetsService.dart';
import 'package:flutter/foundation.dart';
import '../services/AuthService.dart';
import 'package:flutter/material.dart';
import 'helpers/common.dart';
import 'locale/localized_texts.dart';
import 'ui/login_page.dart';
import 'ui/home_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';


String CODE_VERSION = '24.161.1';

Future<void> main() async {


  Future<bool> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('darkTheme') ?? true;
  }

  WidgetsFlutterBinding.ensureInitialized();
  bool isDark = await loadThemePreference();
  if (!kReleaseMode){
    CODE_VERSION = 'DEBUG';
  }
  runApp(MyApp(isDarkTheme: isDark));

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
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        LocalizedStringsDelegate(),
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
    _checkAuthentication();
    super.initState();

  }

  void _checkAuthentication() async {
    // Verify if session active
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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainMenuPage()));
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
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
