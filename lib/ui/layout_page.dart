import 'dart:convert';

import 'package:client_0_0_1/helpers/common.dart';
import 'package:client_0_0_1/locale/localized_texts.dart';
import 'package:client_0_0_1/ui/markets_page.dart';
import 'package:client_0_0_1/ui/settings_view.dart';
import 'package:client_0_0_1/ui/userinfo_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:client_0_0_1/candlesticks/candlesticks.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;

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

class MainMenuPageState extends State<MainMenuPage> {
  Uint8List? _profilePicBytes;
  int _selectedIndex = 0;
  late List<Candle> candlesList;
  late List<Widget> _pages;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
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
  }

  Future<void> _initializeData() async {
    await _loadUserInfo();
    await _loadProfilePic();
    setState(() {
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
      const HomeScreen(),
      const BlankImageWidget(),
      const MarketsView(),
      SettingsView(onPersonalInfoTap: () => _onItemTapped(3)),
      const UserInfoPage()
    ];

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 1.0,
                color: Colors.black45,
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Colors.deepPurple,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: strings?.home ?? "Home",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.public),
              label: strings?.ranking ?? "Ranking",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.casino_outlined),
              activeIcon: const Icon(Icons.casino),
              label: strings?.liveMarkets ?? 'Live Markets',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: strings?.settings ?? 'Settings',
            ),
            BottomNavigationBarItem(
              icon: (_profilePicBytes != null
                  ? CircleAvatar(
                backgroundImage: MemoryImage(_profilePicBytes!),
                radius: 15,
              )
                  : const Icon(Icons.account_circle_outlined)),
              label: _username,
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      );
    }
  }
}
