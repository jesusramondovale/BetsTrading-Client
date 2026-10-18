import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart';

/// Botón oficial GIS (invisible encima del estilo custom).
/// En web `GoogleSignIn.signIn()` NO entrega idToken; este sí.
Widget buildGoogleSignInWebButton({double minimumWidth = 400}) {
  return SizedBox.expand(
    child: renderButton(
      configuration: GSIButtonConfiguration(
        type: GSIButtonType.standard,
        theme: GSIButtonTheme.outline,
        size: GSIButtonSize.large,
        text: GSIButtonText.continueWith,
        shape: GSIButtonShape.rectangular,
        logoAlignment: GSIButtonLogoAlignment.left,
        minimumWidth: minimumWidth,
      ),
    ),
  );
}
