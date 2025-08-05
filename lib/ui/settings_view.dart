import 'dart:ui';

import 'package:app_settings/app_settings.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/common.dart';
import '../config/config.dart';
import '../services/AuthService.dart';

class SettingsView extends StatefulWidget {

  final VoidCallback onPersonalInfoTap;
  final VoidCallback onShowNotifications;

  const SettingsView({super.key,
    required this.onPersonalInfoTap,
    required this.onShowNotifications,});

  @override
  SettingsViewState createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  bool enableVibration = false;
  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    setState(() {

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
            backgroundColor: Colors.black,
            title: Text(
              strings?.get('changePassword') ?? "Change Password",
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
                    labelText: strings?.get('newPassword') ?? "New Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: strings?.get('confirmPassword') ?? "Confirm Password",
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
                child: Text(strings?.get('cancel') ?? "Cancel"),
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
                          content: Text(strings?.get('success') ?? "Password changed successfully"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(dialogContext).pop(true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings?.get('errorChangingPassword') ?? "Error changing password"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings?.get('passwordMismatch') ?? "Passwords do not match"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(strings?.get('confirm') ?? "Confirm"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openInAppBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.inAppWebView,// navegador interno
    )) {
      Common().actionDialog(context, "Error!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final FlutterSecureStorage _storage = const FlutterSecureStorage();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor : Colors.transparent.withValues(alpha: 0.0),
        title: Text(strings?.get('settings') ?? "Settings",
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w400,
            )),
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
            children: ListTile.divideTiles(
              context: context,
              tiles: [
                // Personal Info
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    onTap: widget.onPersonalInfoTap,
                    child: ListTile(
                      title: Text(
                        strings?.get('personalInfo') ?? 'Personal info',
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),

                // Notifications
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    onTap: widget.onShowNotifications,
                    child: ListTile(
                      title: Text(
                        strings?.get('notifications') ?? 'Notifications',
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),

                // Payment History
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    onTap: () {
                      Common().vibrate(40, 40);
                      Common().unimplementedAction(context, '(Payment history)');
                    },
                    child: ListTile(
                      title: Text(
                        strings?.get('paymentHistory') ?? 'Payment history',
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),

                // Configure Withdrawal Methods (disabled)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () => {
                      Common().vibrate(40, 40),
                      Common().unimplementedAction(context, '(Payment history)'),
                    },
                    child: ListTile(
                      title: Text(
                        strings?.get('configureWithdrawalOptions') ?? 'Configure withdrawal methods',
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),

                // About Us
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    onTap: () {
                      Common().vibrate(40, 40);
                      _openInAppBrowser("https://betstrading.online");
                    },
                    child: ListTile(
                      title: Text(
                        strings?.get('aboutUs') ?? 'About us',
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),

                // Enable Vibration
                SwitchListTile(
                  title: Text(
                    strings?.get('enableVibration') ?? "Enable vibration",
                    style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                  value: enableVibration,
                  inactiveThumbColor: Colors.black,
                  inactiveTrackColor: Colors.grey,
                  onChanged: (bool value) async {
                    Common().vibrate(40, 40);
                    await _saveThemePreference(value);
                    setState(() {
                      enableVibration = value;
                      Common().savePreference('enableVibration', value);
                    });
                  },
                ),

                // Change Password
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    onTap: () async {
                      Common().vibrate(40, 40);
                      showChangePasswordDialog(context, await _storage.read(key: "sessionToken") ?? "none");
                    },
                    child: ListTile(
                      title: Text(
                        strings?.get('changePassword') ?? 'Change password',
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),

                // Advanced App Settings
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    onTap: () {
                      AppSettings.openAppSettings();
                    },
                    child: ListTile(
                      title: Text(
                        strings?.get('advancedSettings') ?? 'Advanced app settings',
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                      trailing: const Icon(Icons.settings_suggest_outlined, size: 40),
                    ),
                  ),
                ),
              ],

            ).toList(),
          ),

        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        child: Text(
            (strings?.get('versionCode') ?? 'Version code: ') + ((!kReleaseMode) ? 'DEBUG': Config.CODE_VERSION),
            textAlign: TextAlign.center),
      ),
    );
  }
}