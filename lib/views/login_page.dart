import 'package:client_0_0_1/main.dart';
import 'package:client_0_0_1/helpers.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

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
          child: Container(
            color: Colors.black, // Color de la barra negra
            height: 1.0, // Altura de la barra negra
          ),
          preferredSize: Size.fromHeight(2.0), // Altura de la barra negra
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
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: LoginForm(),
              ),
            ),
          ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

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
              contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your user name';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TO-DO: Implementar la lógica de inicio de sesión
                    Helpers().unimplementedAction("LogIn()",context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                ),
                child: Text(
                  'Log In',
                  style: TextStyle(fontSize: 16.0, color: Colors.white),
                ),
              ),
              SizedBox(width: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TO-DO: Implementar la lógica de registro
                    Helpers().unimplementedAction("Register()",context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                ),
                child: Text(
                  'Register',
                  style: TextStyle(fontSize: 16.0, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children : [
              TextButton(
                onPressed: () {
                  // TO-DO: Implementar la lógica para la recuperación de contraseña
                  Helpers().unimplementedAction("Password Recovery", context);
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
