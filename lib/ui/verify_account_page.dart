import 'package:betrader/services/AuthService.dart';
import 'package:flutter/material.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import 'camera_page.dart';
import 'login_page.dart';

class VerifyAccountPage extends StatefulWidget {
  final String countryCode;

  VerifyAccountPage({required this.countryCode});

  @override
  _VerifyAccountPageState createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends State<VerifyAccountPage> {
  String _idNumber = "";

  void _navigateToCameraPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CameraPage(countryCode: widget.countryCode)),
    );

    if (result != null) {
      setState(() {
        _idNumber = result;
      });
      _showIdResultDialog();
    }
  }

  void _showIdResultDialog() {
    final strings = LocalizedStrings.of(context);
    showDialog(
      barrierColor: Colors.black.withAlpha(220),
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(strings?.get('verificationResultTitle') ?? 'Verification Result'),
          content: Text(_idNumber.isNotEmpty
              ? '${strings?.get('idNumberTitle') ?? 'Scanned ID Number'}: $_idNumber'
              : strings?.get('idNotFound') ?? 'No valid ID found.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void verifyExitPopDialog(String aTitle, String aBody, BuildContext aContext) {
    showDialog(
      barrierColor: Colors.black.withAlpha(220),
      context: aContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black ,
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
                setState(() {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false,
                  );
                });

              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _validateIDButtonPressed(String anID) {
    //TO-DO: Send ID to controller
    //Common().unimplementedAction(context);
    return AuthService().verifyAccount(anID);
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings?.get('verify') ?? 'Verify Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings?.get('instructionsTitle') ??
                  'To verify your account, follow these steps:',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              strings?.get('instructions') ??
                  '1. Make sure you have your ID document handy.\n\n'
                      '2. Click the button below to open the camera.\n\n'
                      '3. Take a clear picture of your ID document.\n\n'
                      '4. Wait a few seconds while we process the image.',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Center(
              child: Row(
                children: [
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.videocam, size: 120),
                    onPressed: _navigateToCameraPage,
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.fact_check_outlined, size: 120),
                    onPressed: _navigateToCameraPage,
                  ),
                  Spacer(),
                ],
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _navigateToCameraPage,
                icon: Icon(Icons.camera_alt, size: 40),
                label: Text(strings?.get('scanButton') ?? 'Scan Document',
                    style: TextStyle(fontSize: 20)),
              ),
            ),
            if (_idNumber.isNotEmpty) ...[
              SizedBox(height: 30),
              Text(
                strings?.get('idNumberTitle') ?? 'Scanned ID Number:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                _idNumber,
                style: TextStyle(fontSize: 18, color: Colors.blueAccent),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: _idNumber.isNotEmpty
          ? Container(
              width: 180,
              height: 56,
              child: FloatingActionButton(
                onPressed: () async {

                  int? response = await _validateIDButtonPressed(_idNumber);
                  // OK
                  if (response == 0) {
                    verifyExitPopDialog(
                        strings?.get('success') ?? "Success",
                        strings?.get('accountVerifiedSuccess') ??
                            "Account succesfully verified",
                        context);
                  }
                  // ERROR
                  else if (response == 1) {
                    Common().popDialog(
                        "Ooops ...",
                        strings?.get('accountVerificationError') ??
                            "Error verifying account",
                        context);
                  }
                  //Navigator.pop(context);
                },
                child: Row(
                  children: [
                    SizedBox(width: 4),
                    Icon(Icons.check),
                    Text(
                      " ${strings?.get('verify') ?? "Verify account"}",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                tooltip: 'ID Verified',
              ))
          : null,
    );
  }
}


