import 'dart:convert';
import 'dart:ui';
import 'package:betrader/helpers/slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Services/bets_service.dart';
import '../locale/localized_texts.dart';
import '../helpers/common.dart';
import 'layout_page.dart';

/// A page shown to first-time users for setting up their password.
///
/// Displays after Google sign-in for users who haven't set a password yet.
/// Allows users to create a password and complete their account setup.
class FirstTimePage extends StatefulWidget {
  const FirstTimePage({super.key});

  @override
  State<FirstTimePage> createState() => _FirstTimePageState();
}

class _FirstTimePageState extends State<FirstTimePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _coinIconBase64;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _passwordError;
  String? _confirmPasswordError;
  String? _userId;

  Future<void> _init() async {
    final bytes = await rootBundle.load('assets/new_icon.png');
    final base64 = base64Encode(bytes.buffer.asUint8List());
    final userId = await _storage.read(key: 'sessionToken');

    setState(() {
      _coinIconBase64 = base64;
      _userId = userId;
    });
  }

  Future<void> _loadCoinImage() async {
    final bytes = await rootBundle.load('assets/new_icon.png');
    final base64 = base64Encode(bytes.buffer.asUint8List());
    final userId = await _storage.read(key: "sessionToken") ?? "none";
    setState(() {
      _coinIconBase64 = base64;
      _userId = userId;
    } );
  }

  void _validateForm() {
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;

      final password = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (password.isEmpty) {
        _passwordError = LocalizedStrings.of(context)?.get('thisFieldIsRequired') ?? "Field required";
      } else if (!_isPasswordValid(password)) {
        _passwordError = LocalizedStrings.of(context)?.get('passwordRequirements') ??
            "Password must contain 12 characters, one uppercase and one number.";
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordError = LocalizedStrings.of(context)?.get('thisFieldIsRequired') ?? "Field required";
      } else if (password != confirmPassword) {
        _confirmPasswordError = LocalizedStrings.of(context)?.get('passwordMismatch') ?? "Passwords do not match";
      }
    });
  }

  bool _isPasswordValid(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final longEnough = password.length >= 12;
    return hasUppercase && hasNumber && longEnough;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    _loadCoinImage();
    final strings = LocalizedStrings.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
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
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      strings?.get('createPasswordInfo') ??
                          "To proceed with withdrawals, you must first create a secure password.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                        fontSize: 22,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        style: GoogleFonts.montserrat(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: strings?.get('newPassword') ?? "New Password",
                          labelStyle: GoogleFonts.montserrat(color: Colors.white70, fontSize: 16),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    if (_passwordError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 12),
                        child: Text(
                          textAlign: TextAlign.start,
                          _passwordError!,
                          style: GoogleFonts.montserrat(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_showPassword,
                        style: GoogleFonts.montserrat(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: strings?.get('confirmPassword') ?? "Confirm Password",
                          labelStyle: GoogleFonts.montserrat(color: Colors.white70, fontSize: 16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_confirmPasswordError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 6),
                        child: Text(
                          textAlign: TextAlign.start,
                          _confirmPasswordError!,
                          style: GoogleFonts.montserrat(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          textAlign: TextAlign.end,
                          LocalizedStrings.of(context)!.get('slideToConfirm') ?? "Slide to confirm",
                          style: GoogleFonts.syncopate(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (_coinIconBase64 != null)
                      SlideToConfirm(
                        betAmount: -1,
                        icon: _coinIconBase64!,
                        onSlideComplete: () async {
                          FocusManager.instance.primaryFocus?.unfocus();
                          _validateForm();

                          if (_passwordError != null || _confirmPasswordError != null) return;

                          final response = await Common().postRequestWrapper('Auth', 'NewPassword',
                              { 'username' : _userId , 'password' : _confirmPasswordController.text.trim() });

                          if (response['statusCode'] == 200) {
                            Common().showFloatingSnack(
                              context,
                              strings?.get('successPassword') ?? "Password created successfully",
                              theDuration: 5,
                            );
                            String? id = await _storage.read(key: 'sessionToken');
                            await BetsService().getUserInfo(id!);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const MainMenuPage()),
                            );
                          } else {
                            Common().showFloatingSnack(
                              context,
                              strings?.get('errorChangingPassword') ?? "Oops... error",
                              backgroundColor: Colors.red,
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
