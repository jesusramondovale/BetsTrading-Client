import 'dart:ui';

import 'package:app_settings/app_settings.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/ui/retire_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getBool('enableVibration');
    setState(() {
      enableVibration = storedValue ?? false;
    });
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkTheme', isDark);
  }

  Future<void> _openInAppBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,// navegador interno
    )) {
      Common().showFloatingSnack(context, "Error!", backgroundColor: Colors.red);
    }
  }

  Future<bool?> showChangePasswordDialog(
      BuildContext context,
      String token,
      ) async  {
    bool _showNewPassword = false;
    final strings = LocalizedStrings.of(context);
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final Color bgColor = Colors.grey[900]!;
    final Color fieldColor = Colors.grey[850]!;
    final Color textColor = Colors.white;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) Navigator.pop(dialogContext, false);
          },
          child: AlertDialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              strings?.get('changePassword') ?? "Change Password",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: textColor,
              ),
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: TextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      style: GoogleFonts.montserrat(color: textColor),
                      decoration: InputDecoration(
                        labelText: strings?.get('currentPassword') ?? "Current Password",
                        labelStyle: GoogleFonts.montserrat(color: textColor),
                        filled: true,
                        fillColor: fieldColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings?.get('thisFieldIsRequired') ?? "Required";
                        }
                        return null;
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: StatefulBuilder(
                      builder: (context, setState) => TextFormField(
                        controller: newPasswordController,
                        obscureText: !_showNewPassword,
                        style: GoogleFonts.montserrat(color: textColor),
                        decoration: InputDecoration(
                          labelText: strings?.get('newPassword') ?? "New Password",
                          labelStyle: GoogleFonts.montserrat(color: textColor),
                          filled: true,
                          errorMaxLines: 3,
                          fillColor: fieldColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showNewPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() => _showNewPassword = !_showNewPassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return strings?.get('thisFieldIsRequired') ?? "Field required";
                          }
                          final hasUppercase = value.contains(RegExp(r'[A-Z]'));
                          final hasNumber = value.contains(RegExp(r'[0-9]'));
                          final longEnough = value.length >= 12;

                          if (!hasUppercase || !hasNumber || !longEnough) {
                            return strings?.get('passwordRequirements') ??
                                "Password must contain 12 characters, one uppercase and one number.";
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  Container(
                    child: TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      style: GoogleFonts.montserrat(color: textColor),
                      decoration: InputDecoration(
                        labelText: strings?.get('confirmPassword') ?? "Confirm Password",
                        labelStyle: GoogleFonts.montserrat(color: textColor),
                        filled: true,
                        fillColor: fieldColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings?.get('thisFieldIsRequired') ?? "Field required";
                        }
                        if (value != newPasswordController.text) {
                          return strings?.get('passwordMismatch') ?? "Passwords do not match";
                        }
                        if (value == newPasswordController.text && value == currentPasswordController.text) {
                          Common().showFloatingSnack(context, "¿Desayunaste payaso 🤡?", backgroundColor: Colors.pink[300]!);
                          return "";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                  textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
                child: Text(strings?.get('cancel') ?? "Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (_formKey.currentState?.validate() != true) return;

                  int result = await AuthService().changePassword(
                    token,
                    currentPasswordController.text,
                    newPasswordController.text,
                  );

                  if (result == 0) {
                    Common().showFloatingSnack(context, strings?.get('successPassword') ?? "Password changed successfully");
                    Navigator.of(dialogContext).pop(true);
                  } else {
                    Common().showFloatingSnack(context, strings?.get('errorChangingPassword') ?? "Error changing password", backgroundColor: Colors.red);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: textColor,
                  textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(strings?.get('confirm') ?? "Confirm"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
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
              color: Colors.white70.withValues(alpha: 0.25),
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
                      Common().showFloatingSnack(context, '(Payment history)', backgroundColor: Colors.white);
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
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const RetireMethodsPage()),
                      );
                      if (changed == true) {
                        Navigator.pop(context, true);
                      }
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

                // Enable Vibration
                SwitchListTile(
                  title: Text(
                    strings?.get('enableVibration') ?? "Enable vibration",
                    style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                  value: enableVibration,
                  inactiveThumbColor: Colors.black,
                  inactiveTrackColor: Colors.grey,
                  activeColor: Colors.greenAccent,
                  onChanged: (bool value) async {
                    Common().vibrate(40, 40);
                    await _saveThemePreference(value);
                    setState(() {
                      enableVibration = value;
                      Common().savePreference('enableVibration', value);
                    });
                  },
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
                      trailing: const Icon(FontAwesomeIcons.gears, size: 40),
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