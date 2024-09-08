import 'dart:math';

import 'package:betrader/locale/localized_texts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/common.dart';
import '../config/config.dart';
import 'aboutus_page.dart';

class SettingsView extends StatefulWidget {

  final VoidCallback onPersonalInfoTap;
  const SettingsView({super.key, required this.onPersonalInfoTap});

  @override
  SettingsViewState createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  bool isDark = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    bool darkTheme = prefs.getBool('darkTheme') ?? true;
    setState(() {
      isDark = darkTheme;
    });
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkTheme', isDark);
  }


  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings?.settings ?? "Settings"),
        backgroundColor:
        Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            ListTile(
              title: Text(strings?.personalInfo ?? 'Personal info'),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onPersonalInfoTap
            ),
            ListTile(
              title: Text(strings?.changePassword ?? "Change password"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Common().unimplementedAction(context, "(Change Password"),
            ),
            ListTile(
              title: Text(strings?.notifications ?? 'Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Common().showLocalNotification("Test" , Random().nextInt(100), "payload");
              }

            ),
            ListTile(
              title: Text(strings?.contentSettings ?? 'Content settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Common().unimplementedAction(context , '(Content settings)'),
            ),
            ListTile(
              title:  Text(strings?.paymentHistory ?? 'Payment history'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Common().unimplementedAction(context , '(Payment history)'),
            ),
            ListTile(
              title: Text(strings?.aboutUs ?? 'About us'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutUsPage()),
                  ),
            ),
            SwitchListTile(
              title: Text(strings?.darkMode ?? "Dark mode"),
              value: isDark,
              onChanged: (bool value) async {
                await _saveThemePreference(value);
                setState(() {
                  isDark = value;
                  Common().exitPopDialog(strings?.attention ?? "Attention!" , strings?.needToRestart ?? "App must restart", context);
                });
              },
            ),
          ],
        ).toList(),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        child: Text(
            (strings?.versionCode ?? 'Version code: ') + ((!kReleaseMode) ? 'DEBUG': Config.CODE_VERSION),
            textAlign: TextAlign.center),
      ),
    );
  }
}