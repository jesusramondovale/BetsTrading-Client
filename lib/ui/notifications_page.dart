import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_settings/app_settings.dart';

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
  bool _newsNotifications = true;

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
            title: Text(strings?.enableNotifications ?? 'Enable notifications',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),),
            value: _enableNotifications,
            onChanged: (bool value) {
              setState(() => _enableNotifications = value);
              _savePreference('enableNotifications', value);
            },
          ),
          SwitchListTile(
            inactiveThumbColor: Colors.black,
            inactiveTrackColor: !_enableNotifications ? Colors.white24 : Colors.grey,
            title: Text(strings?.trendingNotifications ?? 'Trending notifications',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),),
            value: _trendingNotifications && _enableNotifications,
            onChanged: (bool value) {
              if (_enableNotifications){
                setState(() => _trendingNotifications = value);
                _savePreference('trendingNotifications', value);
              }
            },
          ),
          SwitchListTile(
            inactiveThumbColor: Colors.black,
            inactiveTrackColor: !_enableNotifications ? Colors.white24 : Colors.grey,
            title: Text(strings?.bettingNotifications ?? 'Betting notifications',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),),
            value: _bettingNotifications && _enableNotifications,
            onChanged: (bool value) {
              if (_enableNotifications){
                setState(() => _bettingNotifications = value);
                _savePreference('bettingNotifications', value);
              }
            },
          ),
          SwitchListTile(
            inactiveThumbColor: Colors.black,
            inactiveTrackColor: !_enableNotifications ? Colors.white24 : Colors.grey,
            title: Text(strings?.newsNotifications ?? 'News notifications',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),),
            value: _newsNotifications && _enableNotifications,
            onChanged: (bool value) {
              if (_enableNotifications){
                setState(() => _newsNotifications = value);
                _savePreference('newsNotifications', value);
              }
            },
          ),
          ListTile(
            title: Text(strings?.advancedSettings ?? 'Advanced app settings',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),),
            trailing: const Icon(Icons.settings),
            onTap: () {
              AppSettings.openAppSettings();
            },
          ),
        ],
      ),
    );
  }

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
}
