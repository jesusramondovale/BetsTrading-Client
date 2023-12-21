// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import '../customWidgets/marketWidgets.dart';
import '../helpers/common.dart';
import '../services/AuthService.dart';
import 'package:client_0_0_1/ui/userinfo_page.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:candlesticks/candlesticks.dart';

import '../enums/stocks.dart';
import 'login_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int _selectedIndex = 0;
  List<Candle> candlesList = Common().generateRandomCandles(150);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _username = '';

  final List<String> _titles = [
    'Home',
    'Markets',
    'Settings',
    'Profile'
  ];
  late final List<Widget> _pages;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _loadUserInfo() async {
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
    _loadUserInfo();

    candlesList = Common().generateRandomCandles(150); // Inicialización aquí
    _pages = [
      //TODO:
      const BlankImageWidget(),
      Center(
        child: Candlesticks(candles: candlesList),
      ),
      const BlankImageWidget(),
      const UserInfoPage(),
    ];

  }

  @override
  Widget build(BuildContext context) {
    _titles[3] = "Info  |  $_username";
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(_titles[_selectedIndex]),
      ),
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black12,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph),
            label: 'Markets',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle),
            label: _username,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}





