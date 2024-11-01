import 'package:betrader/locale/localized_texts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        title: Text(strings?.settings ?? "Settings",
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w400,
            )),
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
                await Common().showLocalNotification("Betrader" , "Test",  {"key":"value"});
              }

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
            ListTile(
              title: Text(
                "Demo / Real",
                style: TextStyle(fontSize: 16),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRealNotifier.value)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Image.asset('assets/alpha_vantage.png', width: 55),
                    ),
                  Switch(
                    value: isRealNotifier.value,
                    inactiveThumbColor: Colors.black,
                    inactiveTrackColor: Colors.grey,
                    onChanged: (bool value) {
                      isRealNotifier.value = value;
                      setState(() {

                      });
                    },
                  ),
                ],
              ),
            ),
            SwitchListTile(
              title: Text(strings?.darkMode ?? "Dark mode"),
              value: isDark,
              inactiveThumbColor: Colors.black,
              inactiveTrackColor: Colors.grey,
              onChanged: (bool value) async {
                await _saveThemePreference(value);
                setState(() {
                  isDark = value;
                  Common().exitPopDialog(strings?.attention ?? "Attention!" , strings?.needToRestart ?? "App must restart", context);
                });
              },
            )

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