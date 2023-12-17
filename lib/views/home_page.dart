// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:client_0_0_1/AuthService.dart';
import 'package:client_0_0_1/helpers.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _username = '';

  final List<String> _titles = [
    'Home',
    'Graphs',
    'Settings',
    'Profile'
  ];
  final List<Widget> _pages = [
    //TO-DO
    const BlankImageWidget(),
    //TO-DO
    const BlankImageWidget(),
    //TO-DO
    const BlankImageWidget(),
    const UserInfoPage(),
  ];

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

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _readUserInfo() async {
    Map<String, String> userInfo = {};

    List<String> keys = [
      'fullname', 'username', 'email', 'birthday', 'address', 'country', 'lastsession'
    ];

    for (String key in keys) {
      String? value = await _storage.read(key: key);
      if (value != null && key == 'birthday') {
        DateTime date = DateTime.parse(value);
        value = DateFormat('d MMMM yyyy').format(date);
      }
      if (value != null && key == 'lastsession') {
        DateTime utcDate = DateTime.parse(value);
        DateTime localDate = utcDate.toLocal();
        value = DateFormat("HH'h'mm (dd-MM-yyyy)").format(localDate);
      }
      userInfo[key] = value ?? 'Not available';
    }
    return userInfo;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: FutureBuilder<Map<String, String>>(
        future: _readUserInfo(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            List<Widget> listItems = snapshot.data!.entries.map((entry) {
              String title = '';
              switch (entry.key) {
                case "lastsession":
                  title = 'Last Session';
                  break;
                case "fullname":
                  title = 'Full Name';
                  break;
                case "username":
                  title = 'User Name';
                  break;
                case "email":
                  title = 'E-mail';
                  break;
                default:
                  title = Helpers().capitalizeFirstLetter(entry.key.toString());
              }

              Widget subtitle;
              if (entry.key == 'country') {
                subtitle = Row(
                  children: [
                    Text(entry.value),
                    const SizedBox(width: 8),

                    CountryFlag.fromCountryCode(
                      Helpers().getCountryCode(entry.value).toString(),
                      height: 18,
                      width: 25,
                      borderRadius: 5,
                    ),
                  ],
                );
              } else {
                subtitle = Text(entry.value);
              }

              return ListTile(
                leading: Helpers().getIconForUserInfo(entry.key),
                title: Text(title),
                subtitle: subtitle,
              );
            }).toList();

            listItems.add(
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log Out'),
                onTap: () async {
                  String? id = await _storage.read(key: 'sessionToken');
                  final response = await AuthService().logOut(id.toString());
                  if (response['success'])
                  {
                    await _storage.deleteAll();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                          (Route<dynamic> route) => false,
                    );
                  } else
                  {
                    Helpers().popDialog("Oops...", "${response['message']}" , context);
                  }

                  },
              ),
            );

            return ListView(children: listItems);
          } else {
            return const Center(child: Text('No info available!'));
          }
        },
      ),
    );
  }

}


