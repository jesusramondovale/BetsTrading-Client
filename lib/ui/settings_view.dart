import 'dart:io';
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
import '../helpers/common.dart';
import '../config/config.dart';
import '../services/AuthService.dart';
import 'layout_page.dart';

class SettingsView extends StatefulWidget {

  final VoidCallback onPersonalInfoTap;
  final VoidCallback onShowNotifications;
  final MainMenuPageController controller;
  const SettingsView({super.key,
    required this.onPersonalInfoTap,
    required this.onShowNotifications,
    required this.controller,});

  @override
  SettingsViewState createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  static const _START_TUTORIAL_FLAG = 'START_TUTORIAL';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool enableVibration = false;
  bool dollarCurrency = false;
  bool _loaded = false;


  Future<bool?> showChangePasswordDialog(
      BuildContext context,
      String token,
      ) async {
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
                  // Current password
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

                  // New password + Confirm password (StatefulBuilder)
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        children: [
                          // New password
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: TextFormField(
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

                          // Confirm password
                          Container(
                            child: TextFormField(
                              controller: confirmPasswordController,
                              obscureText: !_showNewPassword,
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
                                if (value == newPasswordController.text &&
                                    value == currentPasswordController.text) {
                                  Common().showFloatingSnack(
                                    context,
                                    "¿Desayunaste payaso 🤡?",
                                    backgroundColor: Colors.pink[300]!,
                                  );
                                  return "";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      );
                    },
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
                    Common().showFloatingSnack(
                        context,
                        strings?.get('successPassword') ??
                            "Password changed successfully");
                    Navigator.of(dialogContext).pop(true);
                  } else if (result == 1) { // NOT FOUND
                    Common().showFloatingSnack(
                      context,
                      strings?.get('userOrEmailNotFound') ??
                          "Mail not found",
                      backgroundColor: Colors.red,
                    );
                  }
                  else {
                    Common().showFloatingSnack(
                      context,
                      strings?.get('errorChangingPassword') ??
                          "Error changing password",
                      backgroundColor: Colors.red,
                    );
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


  Future<bool?> showRestartDialog(BuildContext context) async {
    final strings = LocalizedStrings.of(context);
    final Color bgColor = Colors.grey[900]!;
    final Color textColor = Colors.white;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) exit(0);
          },
          child: AlertDialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              strings?.get('needToRestart') ?? "The application needs to be restarted. Please enter again",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: textColor,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  exit(0);
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


  Future<void> _saveEnableVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableVibration', value);
  }

  Future<void> _saveDollarCurrency(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dollarCurrency', value);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      enableVibration = prefs.getBool('enableVibration') ?? false;
      dollarCurrency = prefs.getBool('dollarCurrency') ?? false;
      _loaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final strings = LocalizedStrings.of(context);
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
                    onTap: () {
                      Common().applyImmersive();
                      widget.onPersonalInfoTap;
                    },
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
                    onTap: () {
                      widget.onShowNotifications;
                      Common().applyImmersive();
                    },
                    child: ListTile(
                      title: Text(
                        strings?.get('notifications') ?? 'Notifications',
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
                      Common().applyImmersive();
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

                // Change Password
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    onTap: () async {
                      Common().vibrate();
                      Common().applyImmersive();
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

                // Show tutorial
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    onTap: () async {
                      Common().applyImmersive();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove(_START_TUTORIAL_FLAG);
                      for (var k in prefs.getKeys()) {
                        if (k.startsWith('__tutorial_seen__') || k.startsWith('__tutorial_pending__')) {
                          await prefs.remove(k);
                        }
                      }
                      widget.controller.updateIndex(0);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        homeScreenKey.currentState?.startHomeTutorial();
                      });
                      Common().vibrate();
                      if (Navigator.canPop(context)) Navigator.of(context).pop();
                    },
                    child: ListTile(
                      title: Text(
                        strings?.get('showTutorial') ?? 'Show tutorial',
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
                      Common().vibrate();
                      Common().applyImmersive();
                      Common().openInAppBrowser(context,Config.LANDING_PAGE);
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
                  activeColor: Colors.greenAccent,
                  onChanged: (bool value) async {
                    Common().vibrate();
                    Common().applyImmersive();
                    setState(() => enableVibration = value);
                    _saveEnableVibration(value);
                  },
                ),

                // Switch currency EUR-USD
                ListTile(
                  title: Text(
                    strings?.get('changeCurrency') ?? "Change currency",
                    style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                  trailing: CurrencySwitch(
                    value: dollarCurrency,
                    onChanged: (bool newValue) async {
                      Common().vibrate();
                      Common().applyImmersive();
                      setState(() => dollarCurrency = newValue);
                      _saveDollarCurrency(newValue);
                      showRestartDialog(context);
                    },
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

class CurrencySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CurrencySwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 52,
        height: 34,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white70, width: 2),
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[500],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Image.asset(
                  value ? 'assets/dollar.png' : 'assets/euro.png',
                  width: 26,
                  height: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

