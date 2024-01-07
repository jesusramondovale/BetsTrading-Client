// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:convert';
import 'package:client_0_0_1/services/AuthService.dart';
import 'package:client_0_0_1/ui/signin_page.dart';
import 'package:client_0_0_1/locale/localized_texts.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helpers/common.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.0,
        backgroundColor: const Color(0xFFFFFFFF),
        title: const Text(''),

      ),

      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
            child: Center(
              child: Container(
                width: 350,
                margin: const EdgeInsets.only(top: 80.0, bottom: 20.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(1),
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(1),
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
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});
  @override
  _LoginFormState createState() => _LoginFormState();
}

  class _LoginFormState extends State<LoginForm> {
    final _formKey = GlobalKey<FormState>();
    final _usernameController = TextEditingController();
    final _passwordController = TextEditingController();

    @override
    Widget build(BuildContext context) {
      final strings = LocalizedStrings.of(context);

      return Form(
        key: _formKey,

        child: Column(

          children: [
            Image.asset(
              'assets/logo.png',
              width: 200,

              fit: BoxFit.cover,
            ),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: strings?.username ?? 'User name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return strings?.pleaseEnterUsername ?? 'Please enter your user name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: strings?.password ??'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return strings?.pleaseEnterPassword ?? 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Dialog(

                            backgroundColor: const Color(0xFFFFFFFF),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    strokeWidth: 5,
                                    backgroundColor: Colors.blueGrey,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    strings?.connecting ?? "Connecting ...",
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                      //showDialog

                      final passwordBytes = utf8.encode(_passwordController.text.trim());
                      final hashedPassword = sha256.convert(passwordBytes);

                      final result = await AuthService().logIn(
                        _usernameController.text.trim(),
                        hashedPassword.toString(),
                      );

                      Navigator.of(context).pop();

                      if (result['success']) {
                        Common().logInPopDialog(strings?.welcome ?? "Welcome", _usernameController.text.trim(),context);
                      } else {
                        Common().popDialog("Oops...", "${result['message']}" , context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  ),
                  child: Text(
                    strings?.logIn ?? 'Log In',
                    style: const TextStyle(fontSize: 16.0, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignIn()),
                      );

                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  ),
                  child: Text(
                    strings?.signIn ?? 'Register',
                    style: const TextStyle(fontSize: 16.0, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children : [
                TextButton(
                  onPressed: () {
                    // TO-DO
                    Common().unimplementedAction("ResetPassword()", context);
                  },
                  child: Text(
                    strings?.forgotPassword ?? 'Forgot Password?',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  child:  Text(
                    strings?.exit ?? 'Exit',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),

              ]
            )

          ],
        ),
      );
    }
}
