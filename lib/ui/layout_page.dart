import 'dart:convert';

import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/ui/markets_page.dart';
import 'package:betrader/ui/settings_view.dart';
import 'package:betrader/ui/topusers_page.dart';
import 'package:betrader/ui/userinfo_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import '../helpers/common.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;

final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

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

  @override
  void initState() {
    super.initState();
    _initializeData();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Common().showLocalNotification(
          message.notification!.title!,
          message.notification!.body!,
          1 ,
          message.data);
    });

  }

  Future<void> _initializeData() async {
    await _loadUserInfo();
    await _loadProfilePic();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: isDark ? Colors.black : Colors.white,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    FlutterStatusbarcolor.setStatusBarColor(
        Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white);

    final strings = LocalizedStrings.of(context);
    final List<String> titles = [
      strings?.home ?? 'Home',
      strings?.ranking ?? 'Ranking',
      strings?.liveMarkets ?? 'Live Markets',
      strings?.settings ?? 'Settings',
      strings?.profile ?? 'Profile'
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
        controller: _controller,
      ),
      // SETTINGS
      SettingsView(onPersonalInfoTap: () => _controller.updateIndex(3)),
      // PERSONAL INFO
      const UserInfoPage()
    ];

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return

        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  height: 1.0,
                  color: Colors.black45,
                ),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _controller.selectedIndexNotifier,
                    builder: (context, index, _) {
                      return IndexedStack(
                        index: _controller.selectedIndexNotifier.value,
                        children: _pages,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: ValueListenableBuilder<int>(
            valueListenable: _controller.selectedIndexNotifier,
            builder: (context, index, _) {
              return Container(
                height: 66, // Ajusta la altura aquí
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.5),
                      spreadRadius: 10,
                      blurRadius: 10,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  selectedItemColor: Colors.deepPurple,
                  unselectedItemColor: Colors.grey,
                  showUnselectedLabels: false,
                  showSelectedLabels: true,
                  iconSize: 32,
                  items: <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                      label: strings?.home ?? "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.public),
                      label: strings?.ranking ?? "Ranking",
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        width: 34,  // El ancho de tu icono
                        child: Image.asset('assets/logo_simple.png'),
                      ),
                      activeIcon: Container(
                        width: 27,  // El ancho de tu icono
                        child: Image.asset('assets/logo_simple.png'),
                      ),
                      label: strings?.liveMarkets ?? 'Live Markets',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings_outlined),
                      activeIcon: Icon(Icons.settings),
                      label: strings?.settings ?? 'Settings',
                    ),
                    BottomNavigationBarItem(
                      icon: (_profilePicBytes != null
                          ? CircleAvatar(
                        backgroundImage: MemoryImage(_profilePicBytes!),
                        radius: 16, // Reducción del tamaño del avatar
                      )
                          : Icon(Icons.account_circle_outlined)),
                      label: _username,
                    ),
                  ],
                  currentIndex: _controller.selectedIndexNotifier.value,
                  onTap: (index) {
                    _controller.updateIndex(index);
                  },
                  type: BottomNavigationBarType.fixed,
                ),
              );
            },
          ),
        );


    }
  }
}
