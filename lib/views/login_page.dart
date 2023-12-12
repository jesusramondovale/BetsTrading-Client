import 'package:client_0_0_1/main.dart';
import 'package:client_0_0_1/helpers.dart';
import 'package:client_0_0_1/AuthService.dart';
import 'package:client_0_0_1/views/signin_page.dart';
import 'package:flutter/material.dart';


class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,  // Permite que el fondo se extienda detrás de la AppBar
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.white,
        title: const Text('Log In'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: Colors.black, // Color de la barra negra
            height: 1.0, // Altura de la barra negra
          ), // Altura de la barra negra
        ),
      ),

      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
            child: Center(
              child: Container(
                width: 350,
                margin: const EdgeInsets.only(top: 100.0, bottom: 20.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(1), // Agrega opacidad para que la imagen se vea debajo
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
                labelText: 'User name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your user name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
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
                          return const Dialog(

                            backgroundColor: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    strokeWidth: 5,
                                    backgroundColor: Colors.blueGrey,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "Connecting to BetsTrading ..",
                                    style: TextStyle(
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

                      final result = await AuthService().logIn(
                        _usernameController.text.trim(),
                        _passwordController.text.trim(),
                      );

                      Navigator.of(context).pop();

                      if (result['success']) {
                        Helpers().logInPopDialog("Welcome", "Log-In success!" , _usernameController.text.trim(), context);
                      } else {
                        Helpers().popDialog("Oops...", "${result['message']}" , context);
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
                  child: const Text(
                    'Log In',
                    style: TextStyle(fontSize: 16.0, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: () {

                      // Helpers().unimplementedAction("Register()",context);
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
                  child: const Text(
                    'Register',
                    style: TextStyle(fontSize: 16.0, color: Colors.white),
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
                    // TO-DO: Implementar la lógica para la recuperación de contraseña
                    Helpers().unimplementedAction("ResetPassword()", context);
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyHomePage( title: "You're out!")),
                    );
                  },
                  child: const Text(
                    'Exit',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),

              ]
            )

          ],
        ),
      );
    }
}
