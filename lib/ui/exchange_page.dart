import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/ui/store_page.dart';
import 'package:betrader/ui/withdraw_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../helpers/common.dart';
import 'layout_page.dart';

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key, required this.controller});
  final MainMenuPageController controller;
  @override
  State<ExchangePage> createState() => ExchangePageState();
}

class ExchangePageState extends State<ExchangePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _userPoints = '0';
  //TODO Get actual pending balance from backend
  double _pendingBalance = 2500;
  //TODO: Get exchange current options from backend with a determined currency
  final List<Map<String, dynamic>> _exchangeOptions = [
    {'coins': 5000, 'euros': 50},
    {'coins': 10000, 'euros': 100},
    {'coins': 50000, 'euros': 500},
    {'coins': 100000, 'euros': 1000},
    {'coins': 200000, 'euros': 2000},
    {'coins': 500000, 'euros': 5000},

  ];
  bool _isUserPointsHighlighted = false;

  @override
  void initState() {
    super.initState();
    loadPoints();
  }

  Future<void> loadPoints() async {
    final points = await _storage.read(key: 'points') ?? '0';
    setState(() {
      _userPoints = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

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
                        _userPoints,
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      Common().vibrate(40, 30);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StorePage()),
                      );

                      loadPoints();
                    },
                    child: Text(
                      strings?.get('buyMoreCoins') ?? 'Buy more coins',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                        onTapDown: (TapDownDetails details) {
                          if (canExchange) {
                            Common().vibrate(40, 30);
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) => WithdrawPage(coins: requiredCoins , euros: option['euros'], controller: widget.controller),
                              ),
                            );


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
                            const Text('➤',
                                style: TextStyle(fontSize: 20, color: Colors.white)),
                            const Text('➤',
                                style: TextStyle(fontSize: 20, color: Colors.white)),
                            const Text('➤',
                                style: TextStyle(fontSize: 20, color: Colors.white)),
                            const Spacer(),
                            Text(
                              '${option['euros']} EUR',
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
            Card(
              color: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 20, top: 5),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Common().vibrate(40, 30);
                  Common().unimplementedAction(
                    context,
                    'Pending points pressed',
                  );
                },
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
                  child: Row(
                    children: [
                      Text(
                        strings?.get('pendingBalance') ??
                            'Pending points to send',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        NumberFormat('#,###', 'es_ES').format(_pendingBalance) + 'EUR',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
