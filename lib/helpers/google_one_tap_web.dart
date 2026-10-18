import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js_util' as js_util;

import 'web_console_log.dart';

const String _hostId = 'bt-google-one-tap-host';
int _epoch = 0;
bool _buttonReady = false;
Completer<String?>? _pendingCredential;

dynamic _gisId() {
  try {
    if (!js.context.hasProperty('google')) return null;
    final google = js.context['google'];
    if (google == null) return null;
    final accounts = google['accounts'];
    if (accounts == null) return null;
    return accounts['id'];
  } catch (_) {
    return null;
  }
}

html.Element _ensureHost({bool visible = true}) {
  var host = html.document.getElementById(_hostId);
  if (host == null) {
    host = html.DivElement()..id = _hostId;
    html.document.body!.append(host);
  }
  // Esquina superior derecha, por encima de Flutter.
  host.style.cssText = '''
    position: fixed !important;
    top: 16px !important;
    right: 16px !important;
    z-index: 2147483647 !important;
    width: 320px !important;
    min-height: 44px !important;
    pointer-events: auto !important;
    opacity: ${visible ? '1' : '0.02'} !important;
    overflow: visible !important;
  ''';
  return host;
}

Future<bool> _waitGis({Duration timeout = const Duration(seconds: 5)}) async {
  if (_gisId() != null) return true;
  if (html.document.querySelector(
        'script[src="https://accounts.google.com/gsi/client"]',
      ) ==
      null) {
    html.document.head!.append(html.ScriptElement()
      ..src = 'https://accounts.google.com/gsi/client'
      ..async = true);
  }
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (_gisId() != null) return true;
    await Future.delayed(const Duration(milliseconds: 40));
  }
  return _gisId() != null;
}

void _onCredential(dynamic response) {
  try {
    final credential = response == null
        ? null
        : js_util.getProperty(response, 'credential');
    if (credential is String && credential.isNotEmpty) {
      webConsoleLog('[GoogleGIS] credential ok len=${credential.length}');
      if (_pendingCredential != null && !_pendingCredential!.isCompleted) {
        _pendingCredential!.complete(credential);
      }
    }
  } catch (e) {
    webConsoleLog('[GoogleGIS] credential callback error: $e');
  }
}

/// Prepara el botón GIS en la esquina (llamar al montar el login web).
Future<void> prepareGoogleCornerButton({required String clientId}) async {
  if (!await _waitGis()) {
    webConsoleLog('[GoogleGIS] prepare: GIS not ready');
    return;
  }
  final id = _gisId();
  if (id == null) return;

  final host = _ensureHost(visible: false);
  host.children.clear();

  final callback = js_util.allowInterop(_onCredential);
  try {
    js_util.callMethod(id, 'initialize', [
      js_util.jsify({
        'client_id': clientId,
        'callback': callback,
        'auto_select': false,
        'cancel_on_tap_outside': true,
        'context': 'signin',
        'itp_support': true,
        'use_fedcm_for_prompt': false,
        'prompt_parent_id': _hostId,
      }),
    ]);
    js_util.callMethod(id, 'renderButton', [
      host,
      js_util.jsify({
        'type': 'standard',
        'theme': 'outline',
        'size': 'large',
        'text': 'signin_with',
        'shape': 'rectangular',
        'logo_alignment': 'left',
        'width': 300,
      }),
    ]);
    _buttonReady = true;
    webConsoleLog('[GoogleGIS] corner button ready');
  } catch (e) {
    webConsoleLog('[GoogleGIS] prepare error: $e');
    _buttonReady = false;
  }
}

/// Al pulsar "Continue with Google": muestra selector arriba a la derecha
/// (One Tap + botón GIS anclado) y espera el idToken.
Future<String?> promptGoogleOneTap({
  required String clientId,
  void Function(String reason)? onMoment,
}) async {
  final myEpoch = ++_epoch;
  _pendingCredential = Completer<String?>();

  if (!_buttonReady) {
    await prepareGoogleCornerButton(clientId: clientId);
  }
  if (myEpoch != _epoch) return null;

  final id = _gisId();
  if (id == null) {
    onMoment?.call('unavailable');
    return null;
  }

  // Visible en esquina superior derecha.
  final host = _ensureHost(visible: true);

  // 1) One Tap (tarjeta de cuentas arriba-derecha).
  try {
    js_util.callMethod(id, 'prompt', [
      js_util.allowInterop((dynamic notification) {
        try {
          String detail = 'other';
          if (js_util.callMethod(notification, 'isNotDisplayed', []) == true) {
            detail =
                'not_displayed:${js_util.callMethod(notification, 'getNotDisplayedReason', [])}';
          } else if (js_util.callMethod(notification, 'isSkippedMoment', []) ==
              true) {
            detail =
                'skipped:${js_util.callMethod(notification, 'getSkippedReason', [])}';
          } else if (js_util.callMethod(notification, 'isDismissedMoment', []) ==
              true) {
            detail =
                'dismissed:${js_util.callMethod(notification, 'getDismissedReason', [])}';
          } else if (js_util.callMethod(notification, 'isDisplayed', []) ==
              true) {
            detail = 'displayed';
          }
          webConsoleLog('[GoogleGIS] prompt moment=$detail');
          onMoment?.call(detail);
        } catch (e) {
          onMoment?.call('moment_error');
        }
      }),
    ]);
  } catch (e) {
    webConsoleLog('[GoogleGIS] prompt error: $e');
  }

  // 2) Clic en el botón GIS de la esquina → chooser anclado arriba-derecha.
  await Future.delayed(const Duration(milliseconds: 80));
  if (myEpoch != _epoch) return null;
  try {
    final btn = host.querySelector('[role="button"]') ??
        host.querySelector('div[role=button]');
    if (btn is html.Element) {
      webConsoleLog('[GoogleGIS] clicking corner GIS button…');
      btn.click();
    }
  } catch (e) {
    webConsoleLog('[GoogleGIS] corner click error: $e');
  }

  // El caller aplica timeout corto y cae a OAuth si no hay credential.
  return _pendingCredential!.future;
}

void cancelGoogleOneTap() {
  _epoch++;
  if (_pendingCredential != null && !_pendingCredential!.isCompleted) {
    _pendingCredential!.complete(null);
  }
  _pendingCredential = null;
  try {
    final id = _gisId();
    if (id != null) js_util.callMethod(id, 'cancel', []);
  } catch (_) {}
  try {
    final host = html.document.getElementById(_hostId);
    if (host != null) {
      host.style.opacity = '0.02';
    }
  } catch (_) {}
}
