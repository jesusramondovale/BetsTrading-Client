import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CameraPage extends StatelessWidget {
  final String sessionUrl;

  const CameraPage({super.key, required this.sessionUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verificación de identidad")),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(sessionUrl)),
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
      ),
    );
  }
}
