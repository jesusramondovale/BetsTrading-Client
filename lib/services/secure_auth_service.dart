import 'package:betrader/helpers/common.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureAuthService {
  static const String biometricPrefKey = 'enableBiometricAuth';
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isBiometricSupported() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(biometricPrefKey) ?? false;
    final supported = await isBiometricSupported();
    return enabled && supported;
  }

  Future<void> saveBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(biometricPrefKey, value);
  }

  Future<bool> authenticateBiometric(BuildContext context) async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: LocalizedStrings.of(context)?.get('biometricAuthReason') ??
            'Authenticate to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );
      if (!ok) {
        Common().showFloatingSnack(
          context,
          LocalizedStrings.of(context)?.get('errorTryAgain') ?? 'Error. Try again',
          backgroundColor: Colors.red,
        );
      }
      return ok;
    } catch (_) {
      Common().showFloatingSnack(
        context,
        LocalizedStrings.of(context)?.get('errorTryAgain') ?? 'Error. Try again',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  Future<String?> requestStepUpToken(String purpose, {double? maxAmountCoins}) async {
    final response = await Common().postRequestWrapper(
      'Auth',
      'StepUpToken',
      {
        'purpose': purpose,
        'maxAmountCoins': maxAmountCoins,
      },
    );

    if (response['statusCode'] == 200 &&
        response['body'] is Map &&
        response['body']['stepUpToken'] != null) {
      return response['body']['stepUpToken'].toString();
    }
    return null;
  }

  Future<String?> runStepUpWithBiometric(
    BuildContext context, {
    required String purpose,
    double? maxAmountCoins,
  }) async {
    final biomOk = await authenticateBiometric(context);
    if (!biomOk) return null;
    final token = await requestStepUpToken(purpose, maxAmountCoins: maxAmountCoins);
    if (token == null && context.mounted) {
      Common().showFloatingSnack(
        context,
        LocalizedStrings.of(context)?.get('errorTryAgain') ?? 'Error. Try again',
        backgroundColor: Colors.red,
      );
    }
    return token;
  }

  Future<String?> promptPasswordDialog(BuildContext context) async {
    final strings = LocalizedStrings.of(context);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            strings?.get('password') ?? 'Password',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: strings?.get('enterPasswordToContinue') ?? 'Enter password to continue',
              labelStyle: const TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings?.get('cancel') ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(strings?.get('confirm') ?? 'Confirm'),
            ),
          ],
        );
      },
    );
  }
}
