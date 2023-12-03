import 'package:flutter/material.dart';

class Helpers {
  void unimplementedAction(String action, BuildContext aContext) {
    showDialog(
      context: aContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text("Unimplemented action",
              style: const TextStyle(color: Colors.white)),
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

}