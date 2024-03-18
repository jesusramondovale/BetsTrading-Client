import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:client_0_0_1/services/AuthService.dart';
import 'package:client_0_0_1/locale/localized_texts.dart';
import 'package:client_0_0_1/helpers/common.dart';
import 'package:client_0_0_1/ui/signin_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {

    double bottomMargin = MediaQuery.of(context).size.height/10;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.0,
        title: const Text(''),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(16.0),
            margin: EdgeInsets.only(bottom: bottomMargin),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: Theme.of(context).colorScheme.onBackground,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onBackground,
                  spreadRadius: 3,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const LoginForm(),
          ),
        ),
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
  bool _showSignInWithGoogleApple = true;

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Image.asset('assets/logo.png', width: 200, fit: BoxFit.cover),
          const Padding(padding: EdgeInsets.all(10.0)),
          if (_showSignInWithGoogleApple) ...[
            _buildGoogleSignInButton(strings!),
            const SizedBox(height: 8),
            _buildAppleSignInButton(strings),
            const SizedBox(height: 10),
          ] else ...[
            _buildUsernameField(strings!),
            const SizedBox(height: 16),
            _buildPasswordField(strings),
            const SizedBox(height: 20),
            _buildLoginAndRegisterButtons(context, strings),
            const SizedBox(height: 16),
            _buildForgotPasswordButton(strings),
          ],
          _buildToggleButton(strings),
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
      onPressed: () async {  // Añade async aquí
        String? token = await AuthService().googleSignIn();
        if (token != "error" && token != null) {
          print("LE TOKEEEEN-> $token");

        } else {

          print("Error al intentar iniciar sesión con Google.");
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/google.png', height: 24.0),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(strings.googleSignIn ?? 'Continue with Google', style: const TextStyle(fontSize: 16, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleSignInButton(LocalizedStrings strings) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () {
        AuthService().appleSignIn();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/apple_black.png', height: 24.0),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(strings.appleSignIn ?? 'Continue with Apple ID', style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField(LocalizedStrings strings) {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(labelText: strings.username ?? 'User name'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return strings.pleaseEnterUsername ?? 'Please enter your username';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(LocalizedStrings strings) {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(labelText: strings.password ?? 'Password'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return strings.pleaseEnterPassword ?? 'Please enter your password';
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
          child: Text(strings.logIn ?? 'Log In'),
        ),
        const Padding(padding: EdgeInsets.all(2.0)),
        ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SignIn()));
          },
          child: Text(strings.signIn ?? 'Register'),
        ),
      ],
    );
  }

  Widget _buildToggleButton(LocalizedStrings strings) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _showSignInWithGoogleApple = !_showSignInWithGoogleApple;
        });
      },
      child: Text(_showSignInWithGoogleApple ? (strings.commonSignIn ?? "E-mail log-in") :
            (strings.backToSocialsLogin ?? "Back to Social Logins")),
    );
  }

  Widget _buildForgotPasswordButton(LocalizedStrings strings) {
    return TextButton(
      onPressed: () {
        // Forgot password logic
      },
      child: Text(strings.forgotPassword ?? 'Forgot Password?'),
    );
  }

  void logInHelper(LocalizedStrings strings) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    final passwordBytes = utf8.encode(_passwordController.text.trim());
    final hashedPassword = sha256.convert(passwordBytes);

    try {
      final result = await AuthService().logIn(_usernameController.text.trim(), hashedPassword.toString());
      Navigator.of(context).pop(); // Close the progress dialog

      if (result['success']) {
        Common().logInPopDialog(strings.welcome ?? "Welcome", _usernameController.text.trim(), context);
      } else {
        Common().popDialog("Oops...", result['message'], context);
      }
    } catch (e) {
      Navigator.of(context).pop();
      Common().popDialog("Error", "An unexpected error occurred.", context);
    }
  }
}
