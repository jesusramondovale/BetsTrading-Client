import 'package:client_0_0_1/locale/localized_texts.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/common.dart';

import '../main.dart';

class SettingsView extends StatefulWidget {

  final VoidCallback onPersonalInfoTap;
  const SettingsView({super.key, required this.onPersonalInfoTap});

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
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
                  Common().unimplementedAction(context),
            ),
            ListTile(
              title: Text(strings?.notifications ?? 'Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Common().unimplementedAction(context),
            ),
            ListTile(
              title: Text(strings?.contentSettings ?? 'Content settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Common().unimplementedAction(context),
            ),
            ListTile(
              title:  Text(strings?.paymentHistory ?? 'Payment history'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Common().unimplementedAction(context),
            ),
            ListTile(
              title: Text(strings?.aboutUs ?? 'About us'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Common().unimplementedAction(context),
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
            (strings?.versionCode ?? 'Version code: ') + CODE_VERSION,
            textAlign: TextAlign.center),
      ),
    );
  }
}