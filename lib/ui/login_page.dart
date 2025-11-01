import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:betrader/services/AuthService.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/helpers/common.dart';
import 'package:betrader/ui/signin_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/config.dart';
import '../services/BetsService.dart';
import 'fist_time_page.dart';
import 'layout_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: false,
      ),

      floatingActionButton: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          overlayColor: Colors.transparent.withValues(alpha: 0),
          elevation: 0,
        ),
        onPressed: () => Common().openInAppBrowser(context, Config.INSTAGRAM_PAGE),
        child: Icon(
          FontAwesomeIcons.instagram,
          size: 35,
          color: Colors.white70.withValues(alpha: .5),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.1),
                BlendMode.darken,
              ),
              child: Image.asset(
                'assets/backgn.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.transparent),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(16.0),
                child: const LoginForm(),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(10.0),
        child: Text(
            ((!kReleaseMode) ? 'DEBUG': Config.CODE_VERSION),
            textAlign: TextAlign.center),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showSocialSignIn = true;
  bool _isKeyboardVisible = false;


  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  void logInHelper(LocalizedStrings strings) async {
    showDialog(
      barrierColor: Colors.black.withAlpha(220),
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    final pass = _passwordController.text.trim();

    try {
      final result = await AuthService()
          .logIn(_usernameController.text.trim(), pass.toString());
      Navigator.of(context).pop();

      if (result['success']) {
        String? id = await _storage.read(key: 'sessionToken');
        await BetsService().getUserInfo(id!);
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const MainMenuPage()));

        Common().showFloatingSnack(context, "${strings.get('welcome') ?? "Welcome"}  ${_usernameController.text.trim()}!");

      } else {
        if ("null" == result['message'] || null == result['message']) {
          Common().showFloatingSnack(context,"Oops... ${strings.get("serverUnavailable")}", backgroundColor: Colors.red);
        } else {
          Common().showFloatingSnack(context,"Oops... ${strings.get(result['message'])}", backgroundColor: Colors.red);
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      Common().popDialog("Error", "An unexpected error occurred.", context);
    }
  }

  Future<bool?> showEmailPasswordDialog(BuildContext context) async {
    final strings = LocalizedStrings.of(context);
    final TextEditingController emailController = TextEditingController();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final Color bgColor = Colors.grey[900]!;
    final Color fieldColor = Colors.grey[850]!;
    final Color textColor = Colors.white;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
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
              strings?.get('resetPasswordInfo') ?? "Your account password will be reset and the new one will be sent to your email address",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: textColor,
              ),
            ),
            content: Form(
              key: _formKey,
              child: TextFormField(
                controller: emailController,
                style: GoogleFonts.montserrat(color: textColor),
                decoration: InputDecoration(
                  labelText: strings?.get('email') ?? "Email",
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
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRegex.hasMatch(value)) {
                    return strings?.get('invalidEmail') ?? "Invalid email format";
                  }
                  return null;
                },
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              StatefulBuilder(
                builder: (context, setState) => ElevatedButton(
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (_formKey.currentState?.validate() != true) return;

                    final response = await Common()
                        .postRequestWrapper('Auth','ResetPassword', {"id": emailController.text} , includeJwt: false);

                    if (response['statusCode'] == 200) {
                      Navigator.of(dialogContext).pop(true);
                      Common().showFloatingSnack(
                          context,
                          strings?.get('successPassword') ??
                              "Password changed successfully");

                    } else if (response['statusCode'] == 404){
                      Common().showFloatingSnack(
                          context,
                          strings?.get('userOrEmailNotFound') ??
                              "Mail not found",
                          backgroundColor: Colors.red);

                    } else {
                      Common().showFloatingSnack(
                          context,
                          strings?.get('errorChangingPassword') ??
                              "Error changing password",
                          backgroundColor: Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: textColor,
                    textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600).copyWith(inherit: false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                  Text(strings?.get('newPassword') ?? "New Password"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsernameField(LocalizedStrings strings) {
    return TextFormField(
      cursorColor: Colors.black,
      controller: _usernameController,
      decoration: InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          labelText: "E-mail / " + (strings.get('username') ?? 'User name'),
          labelStyle: GoogleFonts.syncopate(fontSize: 25),
          errorStyle: GoogleFonts.montserrat(
            color: Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          floatingLabelStyle: GoogleFonts.syncopate(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),

      ),
      style: GoogleFonts.montserrat(fontSize: 25),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return strings.get('pleaseEnterUsername') ??
              'Please enter your username';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(LocalizedStrings strings) {
    return TextFormField(
      cursorColor: Colors.black,
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          labelText: (strings.get('password') ?? 'Password'),
          labelStyle: GoogleFonts.syncopate(fontSize: 25),
          errorStyle: GoogleFonts.montserrat(
            color: Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          floatingLabelStyle: GoogleFonts.syncopate(
            color: Colors.white,
              fontWeight: FontWeight.w500,
          ),
      ),
      style: GoogleFonts.montserrat(fontSize: 25),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return strings.get('pleaseEnterPassword') ??
              'Please enter your password';
        }
        return null;
      },
    );
  }

  Widget _buildGoogleSignInButton(LocalizedStrings strings) {
    return ElevatedButton(

      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        minimumSize: const Size(50,50),
        maximumSize: Size(
            MediaQuery.of(context).size.width*0.85,
            50),
      ),
      onPressed: () async {
        int? result = await AuthService().googleSignIn();
        if (result != null && result == 0)
        {
          // Validated
          String? id = await _storage.read(key: 'sessionToken');
          await BetsService().getUserInfo(id!);
          String? username = await _storage.read(key: 'username');
          Common().showFloatingSnack(context, "${strings.get('welcome') ?? "Welcome"} $username!");
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const MainMenuPage()));
        }
        else if (result != null && result == 3) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const FirstTimePage()));
        }
        // First Google login
        else if (result != null && result == 2) {
          // Validated
          String? id = await _storage.read(key: 'sessionToken');
          await BetsService().getUserInfo(id!);
          String? username = await _storage.read(key: 'username');
          Common().showFloatingSnack(context, "${strings.get('welcome') ?? "Welcome"} $username!");
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FirstTimePage()));
        }
        else {
          Common().showFloatingSnack(context, "Ooops... error!", backgroundColor: Colors.red);
          print("Error on Google LogIn.");
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/google.png', height: 30),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(strings.get('googleSignIn') ?? 'Continue with Google',
                style:
                    GoogleFonts.montserrat(fontSize: 16, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildManualLogInButton(LocalizedStrings strings) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(50,50),
        maximumSize: Size(
            MediaQuery.of(context).size.width*0.85,
            50),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      onPressed: () {
        setState(() {
          _showSocialSignIn = !_showSocialSignIn;
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.email, color: Colors.white, size: 25),
          const SizedBox(width: 10),
          Text(
            strings.get('commonSignIn') ?? 'Log In',
            style: GoogleFonts.montserrat(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginAndRegisterButtons(
      BuildContext context, LocalizedStrings strings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600).copyWith(inherit: false),

            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              FocusManager.instance.primaryFocus?.unfocus();
              logInHelper(strings);
            }
          },
          child: Text(strings.get('logIn') ?? 'Log In'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600).copyWith(inherit: false),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SignIn()));
          },
          child: Text(strings.get('signIn') ?? 'Register'),
        ),
      ],
    );
  }

  Widget _buildToggleButton(LocalizedStrings strings) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600).copyWith(inherit: false),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      onPressed: () {
        setState(() {
          _showSocialSignIn = !_showSocialSignIn;
        });
      },
      child: Text(
        _showSocialSignIn
            ? (strings.get('commonSignIn') ?? "E-mail log-in")
            : (strings.get('backToSocialsLogin') ?? "Back to Social Logins"),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildForgotPasswordButton(LocalizedStrings strings) {
    return Row(

      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(

          onPressed: () {
            showEmailPasswordDialog(context);
          },
          child: Text(strings.get('forgotPassword') ?? 'Forgot Password?',
              style: GoogleFonts.syncopate(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
        )
      ],
    );
  }

  Widget _buildCreateNewAccountButton(LocalizedStrings strings) {
    return TextButton(
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SignIn()));
      },
      child: Text(strings.get('noAccountRegister') ?? 'Don\'t have an account?',
          style: GoogleFonts.lato(
              decoration: TextDecoration.underline,
              decorationColor: Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blue)),
    );
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final isVisible = bottomInset > 0.0;
    if (isVisible != _isKeyboardVisible) {
      setState(() => _isKeyboardVisible = isVisible);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Form(
      key: _formKey,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.black.withValues(alpha: 0.0)),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                // Texto que se oculta con el teclado
                AnimatedOpacity(
                  opacity: _isKeyboardVisible ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: AutoSizeText(
                    "betrader.v1",
                    textAlign: TextAlign.center,
                    minFontSize: 20,
                    maxLines: 1,
                    style: GoogleFonts.syncopate(
                      fontWeight: FontWeight.w500,
                      fontSize: 38,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset('assets/new_icon.png', width: 200, fit: BoxFit.cover),
                const SizedBox(height: 10),

                if (_showSocialSignIn) ...[
                  _buildGoogleSignInButton(strings!),
                  const SizedBox(height: 8),
                  _buildManualLogInButton(strings),
                  const SizedBox(height: 16),
                  _buildForgotPasswordButton(strings),
                  _buildCreateNewAccountButton(strings)
                ] else ...[
                  _buildUsernameField(strings!),
                  const SizedBox(height: 16),
                  _buildPasswordField(strings),
                  const SizedBox(height: 20),
                  _buildLoginAndRegisterButtons(context, strings),
                  const SizedBox(height: 16),
                  _buildToggleButton(strings),
                  const SizedBox(height: 16),
                  _buildForgotPasswordButton(strings),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
