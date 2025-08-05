import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:betrader/services/AuthService.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/helpers/common.dart';
import 'package:betrader/ui/signin_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/BetsService.dart';
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
        title: const Text(''),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backgn.png',
              fit: BoxFit.cover,
            ),
          ),
          // Contenedor centrado
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width ,
                padding: const EdgeInsets.all(16.0),
                child: const LoginForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showSocialSignIn = true;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Form(
      key: _formKey,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withValues(alpha:0.0),
              ),
            ),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                Image.asset('assets/new_icon.png', width: 200, fit: BoxFit.cover),
                const Padding(padding: EdgeInsets.all(10.0)),
                if (_showSocialSignIn) ...[
                  _buildGoogleSignInButton(strings!),
                  const SizedBox(height: 8),
                  _buildManualLogInButton(strings),
                  const SizedBox(height: 10),
                ] else ...[
                  _buildUsernameField(strings!),
                  const SizedBox(height: 16),
                  _buildPasswordField(strings),
                  const SizedBox(height: 20),
                  _buildLoginAndRegisterButtons(context, strings),
                  const SizedBox(height: 16),
                  _buildForgotPasswordButton(strings),
                  const SizedBox(height: 16),
                  _buildToggleButton(strings),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton(LocalizedStrings strings) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black, backgroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () async {
        int? result = await AuthService().googleSignIn();
        if (result != null && result == 0 ) {

          // Validated
          String? id = await _storage.read(key: 'sessionToken');
          await BetsService().getUserInfo(id!);
          String? username = await _storage.read(key: 'username');
          Common().actionDialog(context, "${strings.get('welcome') ?? "Welcome"}! $username" );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${strings.get('welcome') ?? "Welcome"}! $username"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainMenuPage()));

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Ooops... error!"),
              backgroundColor: Colors.red,
            ),
          );
          print("Error al intentar iniciar sesión con Google.");
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/google.png', height: 24.0),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(strings.get('googleSignIn') ?? 'Continue with Google', style: const TextStyle(fontSize: 16, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildManualLogInButton(LocalizedStrings strings) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.blue,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () {
        setState(() {
          _showSocialSignIn = !_showSocialSignIn;
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.email),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(strings.get('commonSignIn') ?? 'Log In', style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField(LocalizedStrings strings) {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(labelText: "E-mail / " + (strings.get('username') ?? 'User name') ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return strings.get('pleaseEnterUsername') ?? 'Please enter your username';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(LocalizedStrings strings) {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(labelText: strings.get('password') ?? 'Password'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return strings.get('pleaseEnterPassword') ?? 'Please enter your password';
        }
        return null;
      },
    );
  }

  Widget _buildLoginAndRegisterButtons(BuildContext context, LocalizedStrings strings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              logInHelper(strings);
            }
          },
          child: Text(strings.get('logIn') ?? 'Log In'),
        ),
        const Padding(padding: EdgeInsets.all(2.0)),
        ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SignIn()));
          },
          child: Text(strings.get('signIn') ?? 'Register'),
        ),
      ],
    );
  }

  Widget _buildToggleButton(LocalizedStrings strings) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _showSocialSignIn = !_showSocialSignIn;
        });
      },
      child: Text(_showSocialSignIn ? (strings.get('commonSignIn') ?? "E-mail log-in") :
            (strings.get('backToSocialsLogin') ?? "Back to Social Logins")),
    );
  }

  Widget _buildForgotPasswordButton(LocalizedStrings strings) {
    return TextButton(
      onPressed: () {
        // Forgot password logic
      },
      child: Text(strings.get('forgotPassword') ?? 'Forgot Password?'),
    );
  }

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
      final result = await AuthService().logIn(_usernameController.text.trim(), pass.toString());
      Navigator.of(context).pop(); // Close the progress dialog

      if (result['success']) {
        String? id = await _storage.read(key: 'sessionToken');
        await BetsService().getUserInfo(id!);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainMenuPage()));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${strings.get('welcome') ?? "Welcome"}!  ${_usernameController.text.trim()}"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if ("null" == result['message'] || null == result['message']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Oops... ${strings.get("serverUnavailable")}"),
              backgroundColor: Colors.red,
            ),
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Oops... ${strings.get(result['message'])}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      Common().popDialog("Error", "An unexpected error occurred.", context);
    }
  }
}
