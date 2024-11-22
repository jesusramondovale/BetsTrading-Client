import 'package:betrader/locale/localized_texts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/common.dart';
import '../config/config.dart';
import '../services/AuthService.dart';
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
  Future<bool?> showChangePasswordDialog(
      BuildContext context, String token) async {
    final strings = LocalizedStrings.of(context);

    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async {
            Navigator.of(dialogContext).pop(false);
            return false;
          },
          child: AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.grey[200]!,
            title: Text(
              strings?.changePassword ?? "Change Password",
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: strings?.newPassword ?? "New Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: strings?.confirmPassword ?? "Confirm Password",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: Text(strings?.cancel ?? "Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (newPasswordController.text == confirmPasswordController.text) {
                    // Llamar al servicio para cambiar la contraseña
                    int result = await AuthService().changePassword(
                      token,
                      newPasswordController.text,
                    );

                    if (result == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings?.success ?? "Password changed successfully"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(dialogContext).pop(true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings?.errorChangingPassword ?? "Error changing password"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings?.passwordMismatch ?? "Passwords do not match"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(strings?.confirm ?? "Confirm"),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
              onTap: () async =>
                  showChangePasswordDialog(context, await _storage.read(key: "sessionToken") ?? "none")
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