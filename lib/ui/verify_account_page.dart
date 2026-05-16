import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import 'login_page.dart';

/// A page for verifying user identity using Didit KYC service.
///
/// Creates a verification session and displays a web view for the KYC process.
/// Required for enabling withdrawals and certain account features.
class VerifyAccountPage extends StatefulWidget {
  /// The user ID to verify.
  final String userId;

  const VerifyAccountPage({super.key, required this.userId});

  @override
  VerifyAccountPageState createState() => VerifyAccountPageState();
}

class VerifyAccountPageState extends State<VerifyAccountPage> {
  String? _sessionUrl;
  bool _loading = false;

  /// Creates a Didit verification session for KYC processing.
  ///
  /// Fetches a session URL from the server and prepares the web view
  /// for identity verification.
  Future<void> _createDiditSession() async {
    setState(() => _loading = true);

    final response = await Common().postRequestWrapper(
      "Didit",
      "CreateSession",
      {"userId": widget.userId},
    );

    if (response['statusCode'] == 200) {
      setState(() {
        _sessionUrl = response['body']["url"];
      });
    } else {
      Common().showErrorSnack(context);
    }

    setState(() => _loading = false);
  }

  void _openWebView() {
    final strings = LocalizedStrings.of(context);
    if (_sessionUrl == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(strings!.get('verify') ?? "Verify Account")),
          body: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_sessionUrl!)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
            ),
            onPermissionRequest: (controller, request) async {
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              );
            },
            onLoadStop: (controller, url) async {
              if (url.toString().toLowerCase().contains("approved")) {

                LoginPage.navigateToLogin(context);

                Common().showFloatingSnack(
                  context,
                  strings.get("accountVerifiedSuccess") ??
                      "Account successfully verified.\nPlease log in again",
                );
              } else if (url.toString().toLowerCase().contains("error")) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => VerifyAccountPage(userId: widget.userId)),
                      (Route<dynamic> route) => false,
                );
                Common().showErrorSnack(context);
              }
            },
          ),
        ),
      ),
    );
  }

  void verifyExitPopDialog(String aTitle, String aBody, BuildContext aContext) {
    showDialog(
      barrierColor: Colors.black.withAlpha(220),
      context: aContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(aTitle, style: const TextStyle(color: Colors.white)),
          content: Text(aBody,
              style: const TextStyle(fontSize: 16.0, color: Colors.white)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                );
              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(strings?.get('verify') ?? 'Verify Account',
            style: const TextStyle(fontSize: 25)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/android12splash.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withAlpha(50)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings?.get('instructionsTitle') ??
                        'To verify your account, follow these steps:',
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings?.get('instructions') ?? '1. Make sure you have your ID document ready.\n\n2. Click the button below to start the verification process. Then follow the instructions:\n· Take a clear photo (front and back) of your ID document.\n· Take a selfie and finish the process\n· Wait a few seconds while we process the image.\n\nIMPORTANT: if after one minute the system has not confirmed the verification, log out and log back in',
                    style: GoogleFonts.montserrat(fontSize: 17),

                  ),
                  const Spacer(),
                  Center(
                    child: ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor:
                        WidgetStateProperty.all<Color>(Colors.transparent),
                        fixedSize: const WidgetStatePropertyAll<Size>(
                          Size.fromHeight(50),
                        ),
                      ),
                      onPressed: _loading
                          ? null
                          : () async {
                        final status = await Permission.camera.request();

                        if (_sessionUrl == null) {
                          await _createDiditSession();
                        }
                        if (_sessionUrl != null) {
                          if (status.isGranted) {
                            _openWebView();
                          }

                        }
                      },
                      label: Text(
                        strings?.get('verify') ?? 'Verify',
                        style: GoogleFonts.syncopate(
                            fontSize: 20, fontWeight: FontWeight.w200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
