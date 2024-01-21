// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:client_0_0_1/locale/localized_texts.dart';
import '../customWidgets/marketWidgets.dart';

import 'package:client_0_0_1/ui/userinfo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:candlesticks/candlesticks.dart';

import '../helpers/common.dart';
import 'investments_home.dart';
import 'login_page.dart';

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
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int _selectedIndex = 0;
  late List<Candle> candlesList;
  late List<Widget> _pages;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _username = '';

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
    candlesList = Common().generateRandomCandles(150);
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final List<String> titles = [
      strings?.home ?? "Home",
      strings?.liveMarkets ?? "Live Markets",
      strings?.settings ?? 'Settings',
      strings?.profile ?? 'Profile'
    ];
    titles[3] = "Info  |  $_username";
    _pages = [
      const InvestmentScreen(),
      Center(
        child: Stack(
          children: <Widget>[
            Candlesticks(candles: candlesList),
            GridWidget(
                gridLineSpacing: 0.5,
                gridLineColor: Colors.grey.withOpacity(0.8)),
          ],
        ),
      ),
      const BlankImageWidget(),
      const UserInfoPage()
    ];
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
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: strings?.home ?? "Home",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_graph),
            label: strings?.liveMarkets ?? 'Live Markets',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: strings?.settings ?? 'Settings',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle),
            label: _username,
          ),
        ],
        currentIndex: _selectedIndex,
        //selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
