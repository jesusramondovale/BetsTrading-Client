import 'dart:convert';
import 'dart:ui';

import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/ui/markets_page.dart';
import 'package:betrader/ui/topusers_page.dart';
import 'package:betrader/ui/tutorial_page.dart';
import 'package:betrader/ui/userinfo_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/common.dart';
import 'exchange_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'notifications_page.dart';

final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();
final GlobalKey<MarketsViewState> marketsPageKey = GlobalKey<MarketsViewState>();
final GlobalKey<ExchangePageState> exchangePageKey= GlobalKey<ExchangePageState>();

bool _showTutorial = false;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      initialRoute: '/login',
      home: LoginPage(),
    );
  }
}

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  MainMenuPageState createState() => MainMenuPageState();
}

class MainMenuPageController {
  final ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0);

  void updateIndex(int index) {
    Common().vibrate();
    selectedIndexNotifier.value = index;
  }
}

class MainMenuPageState extends State<MainMenuPage> {
  Uint8List? _profilePicBytes;
  late List<Widget> _pages;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final MainMenuPageController _controller = MainMenuPageController();
  String _username = '';
  bool _isLoading = true;
  bool _showNotificationsPage = false;

  Future<void> _loadProfilePic() async {
    String? profilePicString = await _storage.read(key: 'profilepic');
    if (profilePicString != null && profilePicString.isNotEmpty) {
      Uint8List imageBytes;
      if (profilePicString.startsWith('http')) {
        final response = await http.get(Uri.parse(profilePicString));
        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
        } else {
          if (kDebugMode) {
            print('Error loading profile pic!');
          }
          return;
        }
      } else {
        imageBytes = base64Decode(profilePicString);
      }
      setState(() {
        _profilePicBytes = imageBytes;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    String? username = await _storage.read(key: 'username');
    if (username != null) {
      setState(() {
        _username = username;
      });
    }
  }

  Future<void> _initializeData() async {
    await _loadUserInfo();
    await _loadProfilePic();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('first_run') ?? true;

    if (isFirstRun) {
      Permission.notification.request();
      setState(() {
        _showTutorial = true;
      });
      await prefs.setBool('first_run', false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
    _initializeData();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Common().showLocalNotification(
          message.data['type'],
          message.notification!.title!,
          message.notification!.body!,
          message.data);
    });
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));

    FlutterStatusbarcolor.setStatusBarColor(Colors.transparent);

    final strings = LocalizedStrings.of(context);
    final List<String> titles = [
      strings?.get('home') ?? 'Home',
      strings?.get('ranking') ?? 'Ranking',
      strings?.get('liveMarkets') ?? 'Live Markets',
      strings?.get('settings') ?? 'Settings',
      strings?.get('profile') ?? 'Profile'
    ];
    titles[3] = "Info  |  $_username";

    _pages = [
      // HOME
      HomeScreen(
        key: homeScreenKey,
        controller: _controller,
      ),
      // TOP USERS
      TopUsersPage(),
      // MARKETS
      MarketsView(
        key: marketsPageKey,
        controller: _controller,
      ),
      ExchangePage(key: exchangePageKey, controller: _controller),
      // PERSONAL INFO
      const UserInfoPage()
    ];

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Scaffold(
        extendBody: true,
        body: Stack(children: [
          // Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/android12splash.png',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ),

          Positioned.fill(
            child: _showTutorial
                ? TutorialScreen(
                    onDone: () {
                      setState(() {
                        _showTutorial = false;
                      });
                    },
                  )
                : SafeArea(
                    child: Column(
                      children: [
                        Container(
                          height: 1.0,
                          color: Colors.black45,
                        ),
                        Expanded(
                          child: _showNotificationsPage
                              ? NotificationsPage(
                                  onBack: () {
                                    setState(() {
                                      _showNotificationsPage = false;
                                    });
                                  },
                                )
                              : ValueListenableBuilder<int>(
                                  valueListenable:
                                      _controller.selectedIndexNotifier,
                                  builder: (context, index, _) {
                                    return IndexedStack(
                                      index: _controller
                                          .selectedIndexNotifier.value,
                                      children: _pages,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          )
        ]),

        bottomNavigationBar: !_showTutorial
            ? ValueListenableBuilder<int>(
                valueListenable: _controller.selectedIndexNotifier,
                builder: (context, index, _) {
                  return Container(
                    height: 60, // Ajusta la altura aquí
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.transparent.withValues(alpha: 0.1),
                          spreadRadius: 10,
                          blurRadius: 10,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    child: BottomNavigationBar(
                      backgroundColor: Colors.transparent.withValues(alpha: 0.0),
                      selectedItemColor: Colors.white,
                      unselectedItemColor: Colors.white30,
                      showUnselectedLabels: false,
                      showSelectedLabels: true,
                      iconSize: 35,
                      items: <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                          icon: Icon(FontAwesomeIcons.house),
                          label: strings?.get('home') ?? "Home",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(FontAwesomeIcons.earthAmericas),
                          label: "Social",
                        ),
                        BottomNavigationBarItem(
                          icon: SizedBox(
                            width: 40,
                            child: Image.asset('assets/new_icon.png'),
                          ),
                          activeIcon: SizedBox(
                            width: 34,
                            child: Image.asset('assets/new_icon.png'),
                          ),
                          label: strings?.get('liveMarkets') ?? 'Live Markets',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(FontAwesomeIcons.landmark),
                          label: 'Exchange',
                        ),
                        BottomNavigationBarItem(
                          icon: (_profilePicBytes != null
                              ? CircleAvatar(
                                  backgroundImage:
                                      MemoryImage(_profilePicBytes!),
                                  radius: 20, // Reducción del tamaño del avatar
                                )
                              : Icon(Icons.account_circle_outlined)),
                          activeIcon: (_profilePicBytes != null
                              ? CircleAvatar(
                            backgroundImage:
                            MemoryImage(_profilePicBytes!),
                            radius: 15, // Reducción del tamaño del avatar
                          )
                              : Icon(Icons.account_circle_outlined)),
                          label: strings!.get('profileTitle') ?? "Your profile",
                        ),
                      ],
                      currentIndex: _controller.selectedIndexNotifier.value,
                      onTap: (index) {
                        if (_showNotificationsPage) {
                          setState(() {
                            _showNotificationsPage = false;
                            _controller.updateIndex(index);
                          });
                        } else {
                          _controller.updateIndex(index);
                        }
                      },
                      type: BottomNavigationBarType.fixed,
                    ),
                  );
                },
              )
            : null, // Oculta la barra inferior si el tutorial está activo.
      );
    }
  }
}
