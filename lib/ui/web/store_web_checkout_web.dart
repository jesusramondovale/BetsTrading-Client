// @dart=3.3
import 'dart:html';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';

import '../../config/config.dart';

/// Payment Sheet no existe en Flutter web. Stripe.js se monta en un overlay
/// del documento: el slot de Flutter está en un shadow root y `mount('#id')`
/// no lo ve.
Future<bool> confirmWebCardPayment(BuildContext context, String clientSecret) async {
  await _loadStripeJs();
  if (!context.mounted) return false;

  final overlay = _StripePayOverlay(clientSecret);
  return overlay.show();
}

Future<void> _loadStripeJs() async {
  if (_stripeIsLoaded) return;
  final script = ScriptElement()
    ..src = 'https://js.stripe.com/v3/'
    ..async = false;
  document.head!.append(script);
  await script.onLoad.first;
}

bool get _stripeIsLoaded {
  try {
    return _lookupStripe != null;
  } catch (_) {
    return false;
  }
}

@JS('Stripe')
external JSFunction? get _lookupStripe;

@JS('Stripe')
extension type _JSStripe._(JSObject _) implements JSObject {
  external factory _JSStripe(String publishableKey);
  external _JSElements elements(_ElementsOptions options);
  external JSPromise<_ConfirmResult> confirmPayment(_ConfirmOptions options);
}

@JS()
@anonymous
extension type _ElementsOptions._(JSObject _) implements JSObject {
  external factory _ElementsOptions({String clientSecret, _Appearance appearance});
}

@JS()
@anonymous
extension type _Appearance._(JSObject _) implements JSObject {
  external factory _Appearance({String theme});
}

@JS()
extension type _JSElements._(JSObject _) implements JSObject {
  external _JSPaymentElement create(String type);
}

@JS()
extension type _JSPaymentElement._(JSObject _) implements JSObject {
  external void mount(String selector);
  external void unmount();
  external void on(String event, JSFunction handler);
}

@JS()
@anonymous
extension type _ChangeEvent._(JSObject _) implements JSObject {
  external bool get complete;
}

@JS()
@anonymous
extension type _ConfirmOptions._(JSObject _) implements JSObject {
  external factory _ConfirmOptions({
    _JSElements elements,
    _ConfirmParams confirmParams,
    String redirect,
  });
}

@JS()
@anonymous
extension type _ConfirmParams._(JSObject _) implements JSObject {
  external factory _ConfirmParams({String return_url});
}

@JS()
@anonymous
extension type _ConfirmResult._(JSObject _) implements JSObject {
  external _StripeError? get error;
}

@JS()
@anonymous
extension type _StripeError._(JSObject _) implements JSObject {
  external String? get message;
}

class _StripePayOverlay {
  _StripePayOverlay(this.clientSecret);

  static const _mountId = 'betrader-payment-element';

  final String clientSecret;

  late final DivElement _root;
  late final DivElement _error;
  late final ButtonElement _payButton;
  _JSStripe? _stripe;
  _JSElements? _elements;
  _JSPaymentElement? _payment;
  bool _busy = false;
  bool _closed = false;

  Future<bool> show() {
    final previous = document.getElementById('betrader-pay-overlay');
    previous?.remove();

    _root = DivElement()
      ..id = 'betrader-pay-overlay'
      ..style.cssText = '''
        position:fixed;inset:0;z-index:2147483646;
        display:flex;align-items:center;justify-content:center;
        background:rgba(4,8,20,.62);
        font-family:system-ui,Segoe UI,sans-serif;
      ''';

    final card = DivElement()
      ..style.cssText = '''
        width:min(440px,calc(100vw - 32px));
        background:#1A1A2E;color:#fff;border-radius:16px;
        padding:20px 20px 12px;box-sizing:border-box;
      ''';

    final title = HeadingElement.h2()
      ..text = 'Pago'
      ..style.cssText = 'margin:0 0 12px;font-size:24px;font-weight:500;';

    final mountPoint = DivElement()
      ..id = _mountId
      ..style.minHeight = '280px';

    _error = DivElement()
      ..style.cssText = 'color:#ff8a80;font-size:13px;margin-top:8px;line-height:1.35;';

    final actions = DivElement()
      ..style.cssText = 'display:flex;justify-content:flex-end;gap:8px;margin-top:8px;';

    final cancel = ButtonElement()
      ..text = 'Cancelar'
      ..style.cssText = '''
        background:transparent;color:#b388ff;border:0;border-radius:8px;
        padding:10px 16px;font-size:14px;cursor:pointer;
      '''
      ..onClick.listen((_) => _finish(false));

    _payButton = ButtonElement()
      ..text = 'Pagar'
      ..disabled = true
      ..style.cssText = '''
        background:#6750a4;color:#fff;border:0;border-radius:8px;
        padding:10px 18px;font-size:14px;cursor:pointer;
      '''
      ..onClick.listen((_) => _pay());

    actions
      ..append(cancel)
      ..append(_payButton);
    card
      ..append(title)
      ..append(mountPoint)
      ..append(_error)
      ..append(actions);
    _root.append(card);
    document.body!.append(_root);

    try {
      _stripe = _JSStripe(Config.stripePublicRealKey);
      _elements = _stripe!.elements(
        _ElementsOptions(
          clientSecret: clientSecret,
          appearance: _Appearance(theme: 'night'),
        ),
      );
      _payment = _elements!.create('payment');
      _payment!.mount('#$_mountId');
      _payment!.on('change', ((_ChangeEvent event) {
        if (_closed) return;
        _payButton.disabled = _busy || !event.complete;
      }).toJS);
    } catch (e) {
      _showError(e.toString());
    }

    return _root.on['betrader-pay-done'].first.then((event) {
      final detail = (event as CustomEvent).detail;
      return detail == true;
    });
  }

  Future<void> _pay() async {
    final elements = _elements;
    final stripe = _stripe;
    if (_busy || elements == null || stripe == null) return;
    _busy = true;
    _payButton
      ..disabled = true
      ..text = '...';
    _error.text = '';
    try {
      final result = await stripe.confirmPayment(
        _ConfirmOptions(
          elements: elements,
          confirmParams: _ConfirmParams(return_url: Uri.base.toString()),
          redirect: 'if_required',
        ),
      ).toDart;
      final message = result.error?.message;
      if (message != null && message.isNotEmpty) {
        throw Exception(message);
      }
      _finish(true);
    } catch (e) {
      _busy = false;
      _payButton
        ..text = 'Pagar'
        ..disabled = false;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    _error.text = message;
  }

  void _finish(bool paid) {
    if (_closed) return;
    _closed = true;
    try {
      _payment?.unmount();
    } catch (_) {}
    _root.dispatchEvent(CustomEvent('betrader-pay-done', detail: paid));
    _root.remove();
  }
}
