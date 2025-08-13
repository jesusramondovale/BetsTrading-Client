import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/common.dart';
import '../locale/localized_texts.dart';

class NotificationsPage extends StatefulWidget {
  final VoidCallback onBack;

  const NotificationsPage({Key? key, required this.onBack}) : super(key: key);

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  bool _enableNotifications = true;
  bool _trendingNotifications = true;
  bool _bettingNotifications = true;
  bool _newsNotifications = true;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
      _trendingNotifications = prefs.getBool('trendingNotifications') ?? true;
      _bettingNotifications = prefs.getBool('bettingNotifications') ?? true;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            strings?.get('notifications') ?? 'Notifications',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w400,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: widget.onBack,
          ),
        ),
        body: Stack(
          children: [

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



            ListView(
              children: [
                SwitchListTile(
                  inactiveThumbColor: Colors.black,
                  inactiveTrackColor: Colors.grey,
                  title: Text(strings?.get('enableNotifications') ?? 'Enable notifications',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),),
                  value: _enableNotifications,
                  onChanged: (bool value) {
                    setState(() => _enableNotifications = value);
                    Common().savePreference('enableNotifications', value);
                  },
                ),
                SwitchListTile(
                  inactiveThumbColor: Colors.black,
                  inactiveTrackColor: !_enableNotifications ? Colors.white24 : Colors.grey,
                  title: Text(strings?.get('trendingNotifications') ?? 'Trending notifications',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),),
                  value: _trendingNotifications && _enableNotifications,
                  onChanged: (bool value) {
                    if (_enableNotifications){
                      setState(() => _trendingNotifications = value);
                      Common().savePreference('trendingNotifications', value);
                    }
                  },
                ),
                SwitchListTile(
                  inactiveThumbColor: Colors.black,
                  inactiveTrackColor: !_enableNotifications ? Colors.white24 : Colors.grey,
                  title: Text(strings?.get('bettingNotifications') ?? 'Betting notifications',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),),
                  value: _bettingNotifications && _enableNotifications,
                  onChanged: (bool value) {
                    if (_enableNotifications){
                      setState(() => _bettingNotifications = value);
                      Common().savePreference('bettingNotifications', value);
                    }
                  },
                ),
                SwitchListTile(
                  inactiveThumbColor: Colors.black,
                  inactiveTrackColor: !_enableNotifications ? Colors.white24 : Colors.grey,
                  title: Text(strings?.get('newsNotifications') ?? 'News notifications',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),),
                  value: _newsNotifications && _enableNotifications,
                  onChanged: (bool value) {
                    if (_enableNotifications){
                      setState(() => _newsNotifications = value);
                      Common().savePreference('newsNotifications', value);
                    }
                  },
                ),
                ListTile(
                  title: Text('Test!',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),),
                  trailing: const Icon(Icons.notification_important, size: 40),
                  onTap: () async {
                    await Common().showLocalNotification("other", "Betrader" , "Test",  {"key":"value"});
                  },
                ),
              ],
            ),
          ],
        )
    );
  }
}
