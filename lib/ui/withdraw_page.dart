import 'dart:convert';
import 'dart:ui';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/ui/retire_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bets_service.dart';
import '../helpers/common.dart';
import '../helpers/slider.dart';
import '../services/firebase_service.dart';
import '../services/secure_auth_service.dart';
import 'layout_page.dart';
import 'package:intl/intl.dart';

/// A page for withdrawing coins to external payment methods.
///
/// Allows users to select withdrawal methods and convert coins to currency.
/// Displays available withdrawal options based on user's verified methods.
class WithdrawPage extends StatefulWidget {
  /// The number of coins to withdraw.
  final int coins;
  
  /// The equivalent currency amount for the coins.
  final int currencyAmount;
  
  /// Controller for managing the main menu navigation.
  final MainMenuPageController controller;
  
  /// Precargados datos de opciones de retiro
  final Map<String, Map<String, String>>? preloadedUserAvailableMethods;
  
  /// Precargado currency
  final String? preloadedCurrency;
  
  /// Precargado coin icon base64
  final String? preloadedCoinIconBase64;
  
  /// Precargado userId
  final String? preloadedUserId;
  
  const WithdrawPage({
      super.key,
      required this.coins,
      required this.currencyAmount,
      required this.controller,
      this.preloadedUserAvailableMethods,
      this.preloadedCurrency,
      this.preloadedCoinIconBase64,
      this.preloadedUserId});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
  
  /// Precarga los datos necesarios para WithdrawPage antes de navegar
  static Future<Map<String, dynamic>> preloadWithdrawData() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = const FlutterSecureStorage();
    final id = await storage.read(key: 'sessionToken');
    
    // Cargar el icono de la moneda siempre
    final bytes = await rootBundle.load('assets/coin.png');
    final base64 = base64Encode(bytes.buffer.asUint8List());
    
    // Obtener currency siempre
    final currency = (prefs.getBool('dollarCurrency') ?? false) ? 'usd' : 'eur';
    
    if (id == null) {
      return {
        'userAvailableMethods': <String, Map<String, String>>{},
        'currency': currency,
        'coinIconBase64': base64,
        'userId': null,
      };
    }

    final resp = await Common().postRequestWrapper('Info', 'RetireOptions', {});
    
    final map = <String, Map<String, String>>{};
    
    // Función auxiliar para enmascarar
    String mask(String v, {int keep = 4}) {
      if (v.isEmpty) return '—';
      if (v.length <= keep) return v;
      final tail = v.substring(v.length - keep);
      return '•••• $tail';
    }

    if (resp['statusCode'] == 200 && resp['body'] is List) {
      for (final it in resp['body'] as List) {
        final type = (it['type'] ?? '').toString().toLowerCase();
        final data = (it['data'] ?? {}) as Map<String, dynamic>;
        final methodId = (it['id'] ?? '').toString();
        final label = (it['label'] ?? '').toString();

        if (type == 'bank') {
          final iban = (data['iban'] ?? '').toString();
          if (iban.isNotEmpty) {
            map['withdrawMethodBank#$methodId'] = {
              'text': 'IBAN • ${mask(iban)}',
              'label': label,
            };
          }
        } else if (type == 'paypal') {
          final email = (data['email'] ?? '').toString();
          if (email.isNotEmpty) {
            map['withdrawMethodPaypal#$methodId'] = {
              'text': email,
              'label': label,
            };
          }
        } else if (type == 'crypto') {
          final net = (data['network'] ?? '').toString().toUpperCase();
          final addr = (data['address'] ?? '').toString();
          if (addr.isEmpty) continue;

          if (net.contains('BTC')) {
            map['withdrawMethodBTC#$methodId'] = {
              'text': mask(addr, keep: 6),
              'label': label,
            };
          } else if (net.contains('XRP')) {
            map['withdrawMethodXRP#$methodId'] = {
              'text': mask(addr, keep: 6),
              'label': label,
            };
          } else {
            map['withdrawMethodCrypto#$methodId'] = {
              'text': '${net.isEmpty ? "CRYPTO" : net} • ${mask(addr, keep: 6)}',
              'label': label,
            };
          }
        }
      }
    }

    return {
      'userAvailableMethods': map,
      'currency': currency,
      'coinIconBase64': base64,
      'userId': id,
    };
  }
}

class _WithdrawPageState extends State<WithdrawPage> {
  String? _coinIconBase64;
  String? _selectedMethod;
  String? _userId;
  String _currency = 'eur';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Map<String, Map<String, String>> _userAvailableMethods = {};
  final SecureAuthService _secureAuthService = SecureAuthService();

  /// Loads withdrawal page data including available withdrawal methods
  /// and user information.
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = await _storage.read(key: 'sessionToken');
    if (id == null) return;

    final resp =
    await Common().postRequestWrapper('Info', 'RetireOptions', {});

    final map = <String, Map<String, String>>{};

    if (resp['statusCode'] == 200 && resp['body'] is List) {
      for (final it in resp['body'] as List) {
        final type = (it['type'] ?? '').toString().toLowerCase();
        final data = (it['data'] ?? {}) as Map<String, dynamic>;
        final methodId = (it['id'] ?? '').toString();
        final label = (it['label'] ?? '').toString();

        if (type == 'bank') {
          final iban = (data['iban'] ?? '').toString();
          if (iban.isNotEmpty) {
            map['withdrawMethodBank#$methodId'] = {
              'text': 'IBAN • ${_mask(iban)}',
              'label': label,
            };
          }
        } else if (type == 'paypal') {
          final email = (data['email'] ?? '').toString();
          if (email.isNotEmpty) {
            map['withdrawMethodPaypal#$methodId'] = {
              'text': email,
              'label': label,
            };
          }
        } else if (type == 'crypto') {
          final net = (data['network'] ?? '').toString().toUpperCase();
          final addr = (data['address'] ?? '').toString();
          if (addr.isEmpty) continue;

          if (net.contains('BTC')) {
            map['withdrawMethodBTC#$methodId'] = {
              'text': _mask(addr, keep: 6),
              'label': label,
            };
          } else if (net.contains('XRP')) {
            map['withdrawMethodXRP#$methodId'] = {
              'text': _mask(addr, keep: 6),
              'label': label,
            };
          } else {
            map['withdrawMethodCrypto#$methodId'] = {
              'text': '${net.isEmpty ? "CRYPTO" : net} • ${_mask(addr, keep: 6)}',
              'label': label,
            };
          }
        }
      }
    }

    final bytes = await rootBundle.load('assets/coin.png');
    final base64 = base64Encode(bytes.buffer.asUint8List());

    if (!mounted) return;
    setState(() {
      _userId = id;
      _coinIconBase64 = base64;
      if (prefs.getBool('dollarCurrency') == true){
        _currency = 'usd';
      }
      _userAvailableMethods
        ..clear()
        ..addAll(map);

      _selectedMethod = _userAvailableMethods.isEmpty
          ? null
          : _userAvailableMethods.keys.first;
    });
  }

  String _mask(String v, {int keep = 4}) {
    if (v.isEmpty) return '—';
    if (v.length <= keep) return v;
    final tail = v.substring(v.length - keep);
    return '•••• $tail';
  }

  @override
  void initState() {
    super.initState();
    
    // Si hay datos precargados, usarlos inmediatamente
    if (widget.preloadedUserAvailableMethods != null &&
        widget.preloadedCoinIconBase64 != null &&
        widget.preloadedUserId != null) {
      setState(() {
        _userId = widget.preloadedUserId;
        _coinIconBase64 = widget.preloadedCoinIconBase64;
        _currency = widget.preloadedCurrency ?? 'eur';
        _userAvailableMethods
          ..clear()
          ..addAll(widget.preloadedUserAvailableMethods!);
        _selectedMethod = _userAvailableMethods.isEmpty
            ? null
            : _userAvailableMethods.keys.first;
      });
    } else {
      // Si no hay datos precargados, cargar normalmente
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent.withValues(alpha: 0.0),
        elevation: 0,
        title: Text(
          LocalizedStrings.of(context)?.get("withdrawTitle") ??
              "Withdrawal money",
          style: GoogleFonts.montserrat(
            fontSize: 25,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fondo blur
          Positioned.fill(
            child: Image.asset(
              'assets/android12splash.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ),

          // Contenido principal
          Positioned.fill(
            child: SafeArea(
              child: _coinIconBase64 == null
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 6),
                      child: Column(
                        children: [
                          // Header info
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    NumberFormat.compact().format(widget.coins),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 45,
                                      fontWeight: FontWeight.w200,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Image.asset(
                                    'assets/coin.png',
                                    width: 45,
                                    height: 45,
                                  ),
                                ],
                              ),
                              Transform.rotate(
                                angle: 1.5708,
                                child: Icon(
                                  Icons.double_arrow,
                                  size: 40,
                                  color: Colors.green[600],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${widget.currencyAmount}',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 60,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Image.asset(
                                    (_currency == 'eur' ? 'assets/euro.png' : 'assets/dollar.png'),
                                    width: 50,
                                    height: 50,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                LocalizedStrings.of(context)
                                        ?.get('chooseMethod') ??
                                    'Choose your withdrawal method:',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Expanded(
                            child: _userAvailableMethods.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.white24, width: 1),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded,
                                            color: Colors.yellow, size: 60),
                                        const SizedBox(height: 20),
                                        Text(
                                          textAlign: TextAlign.center,
                                          LocalizedStrings.of(context)
                                                  ?.get('noMethods') ??
                                              "You don't have any withdrawal methods configured. Please add one in your profile settings.",
                                          style: GoogleFonts.rajdhani(
                                            fontSize: 26,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Center(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              splashColor: Colors.white24,
                                              highlightColor: Colors.white12,
                                              onTap: () async {
                                                Common().vibrate();
                                                final changed = await Navigator.push<bool>(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => const RetireMethodsPage()),
                                                );
                                                if (changed == true) {
                                                  Navigator.pop(context, true);
                                                }

                                                if (changed == true) {
                                                  await _loadData();
                                                  setState(() {});
                                                }
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: const [
                                                    Icon(
                                                        Icons
                                                            .add,
                                                        size: 25,
                                                        color: Colors.white),
                                                    SizedBox(width: 12),
                                                    Icon(Icons.wallet,
                                                        size: 45,
                                                        color: Colors.white),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _userAvailableMethods.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final methodKey = _userAvailableMethods
                                          .keys
                                          .elementAt(index);
                                      final baseKey = methodKey
                                          .split('#')
                                          .first;
                                      final detail = _userAvailableMethods[methodKey]?['text']!;
                                      final label = _userAvailableMethods[methodKey]?['label']!;
                                      final isSelected =
                                          _selectedMethod == methodKey;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () => setState(() {
                                              _selectedMethod = methodKey;
                                              Common().vibrate();
                                            }),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 16),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.deepPurple
                                                        .withValues(alpha: 0.8)
                                                    : Colors.white
                                                        .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? Colors.deepPurpleAccent
                                                      : Colors.white24,
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isSelected
                                                        ? Icons
                                                            .radio_button_checked
                                                        : Icons
                                                            .radio_button_off,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.white54,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    label ?? LocalizedStrings.of(context)!.get(baseKey) ?? "-",
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 48.0,
                                                  top: 6.0,
                                                  bottom: 6.0),
                                              child: Text(
                                                detail!,
                                                style: GoogleFonts.rajdhani(
                                                  fontSize: 20,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    }),
                          ),

                          const SizedBox(height: 20),

                          const SizedBox(height: 20),

                          ...(_userAvailableMethods.isNotEmpty
                              ? [
                                  Text(
                                    LocalizedStrings.of(context)
                                            ?.get('slideToConfirm') ??
                                        'Slide to Confirm',
                                    maxLines: 1,
                                    style: GoogleFonts.syncopate(
                                      fontSize: 16,
                                      color: Colors.white60,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SlideToConfirm(
                                    icon: _coinIconBase64!,
                                    betAmount: widget.coins.toDouble(),
                                    transformedAmount:
                                        widget.currencyAmount.toDouble(),
                                    transformThumb: true,
                                    onSlideComplete: () {
                                      Common().vibrate(300, 300);
                                      () async {
                                        final strings = LocalizedStrings.of(context);
                                        String fcm = FirebaseService().firebaseToken ?? "null";
                                        final useBiometric = await _secureAuthService.isBiometricEnabled();
                                        String password = "";
                                        String stepUpToken = "";

                                        if (useBiometric) {
                                          final token = await _secureAuthService.runStepUpWithBiometric(
                                            context,
                                            purpose: 'withdraw',
                                            maxAmountCoins: widget.coins.toDouble(),
                                          );
                                          if (token == null) return;
                                          stepUpToken = token;
                                        } else {
                                          final entered = await _secureAuthService.promptPasswordDialog(context);
                                          if (entered == null || entered.isEmpty) return;
                                          password = entered;
                                        }

                                        final response = await Common().postRequestWrapper('Payments', 'RetireBalance', {
                                          'userId': _userId,
                                          'fcm': fcm,
                                          'password': password,
                                          'stepUpToken': stepUpToken,
                                          'currencyAmount': widget.currencyAmount.toDouble(),
                                          'currency': _currency,
                                          'coins': widget.coins.toDouble(),
                                          'method': _selectedMethod
                                        });
                                        if (response['statusCode'] == 200) {
                                          Common().showFloatingSnack(
                                            context,
                                            Common().interpolate(
                                              strings!.get('withdrawCompleted') ??
                                                  "Withdrawal of {coins} coins completed",
                                              {'coins': widget.coins.toString()},
                                            ),
                                          );

                                          await BetsService().getUserInfo(_userId ?? "none");
                                          homeScreenKey.currentState?.loadUserIdAndData();
                                          exchangePageKey.currentState?.loadData();
                                          Navigator.pop(context);
                                        } else {
                                          Common().showFloatingSnack(
                                            context,
                                            strings?.get('errorTryAgain') ?? 'Error. Try again',
                                            backgroundColor: Colors.red,
                                          );
                                        }
                                      }();
                                    },
                                  ),
                                ]
                              : [const SizedBox(height: 80)]),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
