import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../locale/localized_texts.dart';

class NotificationsPage extends StatefulWidget {
  final VoidCallback onBack; // Callback para manejar retroceso

  const NotificationsPage({Key? key, required this.onBack}) : super(key: key);

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  bool _enableNotifications = true;
  bool _trendingNotifications = true;
  bool _bettingNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
      _trendingNotifications = prefs.getBool('trendingNotifications') ?? true;
      _bettingNotifications = prefs.getBool('bettingNotifications') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings?.notifications ?? 'Notifications',
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            inactiveThumbColor: Colors.black,
            inactiveTrackColor: Colors.grey,
            title: Text(strings?.enableNotifications ?? 'Enable notifications'),
            value: _enableNotifications,
            onChanged: (bool value) {
              setState(() => _enableNotifications = value);
              _savePreference('enableNotifications', value);
            },
          ),
          SwitchListTile(
            inactiveThumbColor: Colors.black,
            inactiveTrackColor: Colors.grey,
            title: Text(strings?.trendingNotifications ?? 'Trending notifications'),
            value: _trendingNotifications,
            onChanged: (bool value) {
              setState(() => _trendingNotifications = value);
              _savePreference('trendingNotifications', value);
            },
          ),
          SwitchListTile(
            inactiveThumbColor: Colors.black,
            inactiveTrackColor: Colors.grey,
            title: Text(strings?.bettingNotifications ?? 'Betting notifications'),
            value: _bettingNotifications,
            onChanged: (bool value) {
              setState(() => _bettingNotifications = value);
              _savePreference('bettingNotifications', value);
            },
          ),
        ],
      ),
    );
  }
}
