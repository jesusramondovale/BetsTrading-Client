import 'package:flutter/material.dart';
import 'package:client_0_0_1/main.dart';

class Helpers {

  void unimplementedAction(String action, BuildContext aContext) {
    showDialog(
      context: aContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text("Unimplemented action",
              style: TextStyle(color: Colors.white)),
          content: Text(
            'The requested method $action is not implemented yet. Stay tuned',
            style: const TextStyle(fontSize: 16.0, color: Colors.white),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("I'll wait"),
            ),
          ],
        );
      },
    );
  }
  void popDialog(String aTitle, String aBody, BuildContext aContext) {
    showDialog(
      context: aContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
              aTitle,
              style: const TextStyle(color: Colors.white)),
          content: Text(
            aBody,
            style: const TextStyle(fontSize: 16.0, color: Colors.white),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }
  void logInPopDialog(String aTitle, String aBody, String aUser, BuildContext aContext) {
    showDialog(
      context: aContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
              aTitle,
              style: const TextStyle(color: Colors.white)),
          content: Text(
            aBody,
            style: const TextStyle(fontSize: 16.0, color: Colors.white),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage( title: aUser)),
                );
              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }
}