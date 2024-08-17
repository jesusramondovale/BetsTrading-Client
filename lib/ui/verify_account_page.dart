import 'package:flutter/material.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import 'camera_page.dart';

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
      MaterialPageRoute(builder: (context) => CameraPage(countryCode: widget.countryCode)),
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
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(strings?.verificationResultTitle ?? 'Verification Result'),
          content: Text(_idNumber.isNotEmpty
              ? '${strings?.idNumberTitle ?? 'Scanned ID Number'}: $_idNumber'
              : strings?.idNotFound ?? 'No valid ID found.'),
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

  void _validateIDButtonPressed() {
    //TO-DO: Send ID to controller
    Common().unimplementedAction(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings?.verify ?? 'Verify Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings?.instructionsTitle ??
                  'To verify your account, follow these steps:',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              strings?.instructions ??
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
                  Icon(Icons.videocam, size: 120),
                  Spacer(),
                  Icon(Icons.fact_check_outlined, size: 120),
                  Spacer(),
                ],
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _navigateToCameraPage,
                icon: Icon(Icons.camera_alt, size: 40),
                label: Text(strings?.scanButton ?? 'Scan Document',
                    style: TextStyle(fontSize: 20)),
              ),
            ),
            if (_idNumber.isNotEmpty) ...[
              SizedBox(height: 30),
              Text(
                strings?.idNumberTitle ?? 'Scanned ID Number:',
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
                    onPressed: _validateIDButtonPressed,
                    child: Row(
                      children: [
                        SizedBox(width: 4),
                        Icon(Icons.check),
                        Text(" ${strings?.verify ?? "Verify account"}" ,
                         style: TextStyle(fontSize: 16),),
                      ],
                    ),
                    tooltip: 'ID Verified',
                  ))
          : null, // Si no hay ID, no se muestra el FloatingActionButton
    );
  }
}
