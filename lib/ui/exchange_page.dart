import 'dart:async';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/ui/store_page.dart';
import 'package:betrader/ui/withdraw_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/common.dart';
import 'fist_time_page.dart';
import 'layout_page.dart';

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key, required this.controller});
  final MainMenuPageController controller;
  @override
  State<ExchangePage> createState() => ExchangePageState();
}

class ExchangePageState extends State<ExchangePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _currency = 'eur';
  String _userPoints = '0';
  double _pendingBalance = 0.0;
  List<Map<String, dynamic>> _exchangeOptions = [];
  bool _isUserPointsHighlighted = false;
  Timer? _refreshTimer;

  Future<void> loadData() async {
    final userId = await _storage.read(key: 'sessionToken');
    final points = await _storage.read(key: 'points') ?? '0';
    final pendingBalanceResponse = await Common().postRequestWrapper('Info', 'PendingBalance', {'id': userId});
    final exchangeOptionsResponse = await Common().postRequestWrapper('Info', 'StoreOptions', {'currency': _currency, 'type': 'exchange'}); //TODO Currency
    final prefs = await SharedPreferences.getInstance();

    setState(() {
        _userPoints = points;
        _pendingBalance = pendingBalanceResponse['body']['balance']?.toDouble() ?? 0.0;
        if (pendingBalanceResponse['statusCode'] == 201){ // PASSWORD NOT SET
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const FirstTimePage()));

        }
        _exchangeOptions = List<Map<String, dynamic>>.from(exchangeOptionsResponse['body'] as Iterable);
        if (prefs.getBool('dollarCurrency') ?? false){
          _currency = 'usd';
        }

  });
  }

  @override
  void initState() {
    super.initState();
    loadData();

    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      loadData();
    });

  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    double value = double.tryParse(_userPoints) ?? 0;
    String userPoints = (value % 1 == 0) ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  strings?.get('yourCoins') ?? 'Your coins',
                  style: GoogleFonts.montserrat(
                    fontSize: 25,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userPoints,
                        style: GoogleFonts.roboto(
                          fontSize: 42,
                          fontWeight: FontWeight.w200,
                          color: _isUserPointsHighlighted ? Colors.red : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/coin.png',
                        width: 35,
                        height: 35,
                      ),
                    ],
                  ),

                  ElevatedButton(

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      Common().vibrate();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StorePage()),
                      );

                      loadData();
                    },
                    child: Text(
                      strings?.get('buyMoreCoins') ?? 'Buy more coins',
                      style: GoogleFonts.syncopate(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  strings?.get('exchangeCoinsTitle') ?? 'Exchange coins',
                  style: GoogleFonts.montserrat(
                    fontSize: 30,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                  ),
                )
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _exchangeOptions.length,
                itemBuilder: (context, index) {
                  final option = _exchangeOptions[index];
                  final requiredCoins = option['coins'] as int;
                  final currentPoints = double.tryParse(_userPoints) ?? 0.0;
                  final canExchange = currentPoints >= requiredCoins;

                  return Card(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                        onTapDown: (TapDownDetails details) async {
                          if (canExchange) {
                            Common().vibrate();


                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WithdrawPage(
                                  coins: requiredCoins,
                                  currencyAmount: option['euros'],
                                  controller: widget.controller,
                                ),
                              ),
                            );

                            if (mounted && result == true) {
                              loadData();
                            }

                          } else {
                            Common().vibrate(300, 200);
                            setState(() => _isUserPointsHighlighted = true);
                          }
                        },
                      onTapUp: (TapUpDetails details) async {
                        await Future.delayed(const Duration(milliseconds: 200));
                        if (mounted) {
                          setState(() => _isUserPointsHighlighted = false);
                        };
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Row(
                              children: [
                                Text(
                                  NumberFormat.compact().format(requiredCoins),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Image.asset(
                                  'assets/coin.png',
                                  width: 24,
                                  height: 24,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(FontAwesomeIcons.anglesRight),
                            Icon(FontAwesomeIcons.anglesRight),
                            Icon(FontAwesomeIcons.anglesRight),
                            const Spacer(),
                            Text(
                              '${option['euros']}' + (_currency == 'eur' ? ' EUR' : ' USD'),
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsetsGeometry.fromLTRB(0, 10, 0, 10),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings?.get('pendingBalance') ?? 'Pending points to send',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      NumberFormat('#,###', 'es_ES').format(_pendingBalance) + (_currency == 'eur' ? ' EUR' : ' USD'),
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
