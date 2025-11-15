import 'dart:async';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/ui/store_page.dart';
import 'package:betrader/ui/verify_account_page.dart';
import 'package:betrader/ui/withdraw_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../helpers/common.dart';
import 'first_time_page.dart';
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
  bool _isVerified = false;
  String _userId = '';
  final _kCoinsTag        = GlobalKey();
  final _kGetMoreBtn      = GlobalKey();
  final _kWithdrawGroup   = GlobalKey();
  final _kPendingBalance  = GlobalKey();
  static const _PENDING_FLAG = '__tutorial_pending__exchange_v1';
  static const _SEEN_FLAG    = '__tutorial_seen__exchange_v1';
  TutorialCoachMark? _coach;
  late final VoidCallback _tabListener;



  Future<void> loadData() async {
    final userId = await _storage.read(key: 'sessionToken') ?? '';
    final points = await _storage.read(key: 'points') ?? '0';
    final isVerified = await _storage.read(key: 'isverified');
    final pendingBalanceResponse = await Common().postRequestWrapper('Info', 'PendingBalance', {'id': userId});
    final exchangeOptionsResponse = await Common().postRequestWrapper('Info', 'StoreOptions', {'currency': _currency, 'type': 'exchange'}); //TODO Currency
    final prefs = await SharedPreferences.getInstance();

    setState(() {
        _userId = userId;
        _userPoints = points;
        _isVerified = isVerified == "true";
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

  Future<bool?> showNotVerifiedDialog(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final Color bgColor = Colors.grey.shade900;
    final Color textColor = Colors.white;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) Navigator.pop(dialogContext, false);
          },
          child: AlertDialog(

            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              strings?.get('accountNotVerifiedTitle') ?? "Account not verified",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: textColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings?.get('accountNotVerifiedMsg') ??
                      "Your account has not been verified yet. Please verify it to continue using all features.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: textColor.withValues(alpha: .9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Colors.orangeAccent,
                  ),
                  Icon(
                    Icons.verified_outlined,
                    size: 48,
                    color: Colors.orangeAccent,
                  )
                ],)
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VerifyAccountPage(userId: _userId,)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: textColor,
                  textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(strings?.get('verifyNow') ?? "Verify now"),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------- T U T O R I A L     M E T H O D S    -------------
  Future<void> _markSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_SEEN_FLAG, true);
  }

  Future<void> _clearPending() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_PENDING_FLAG);
  }

  Future<void> _waitForTargetsReady() async {
    for (int i = 0; i < 40; i++) {
      if (!mounted) return;
      final ready =
          _kCoinsTag.currentContext != null &&
              _kGetMoreBtn.currentContext != null &&
              _kWithdrawGroup.currentContext != null &&
              _kPendingBalance.currentContext != null;
      if (ready) break;
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  List<TargetFocus> _buildExchangeTargets() {
    final s = LocalizedStrings.of(context);
    return [
      TargetFocus(
        identify: 'ex_coins',
        keyTarget: _kCoinsTag,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => Common().bubble(
              s?.get('ex_coins_title') ?? 'Your coins',
              s?.get('ex_coins_body') ?? 'This shows your coin balance, Betstrading’s in-app token used for bets, raffles and prize distribution. The amount updates after purchases, wins or refunds.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'ex_getmore',
        keyTarget: _kGetMoreBtn,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => Common().bubble(
              s?.get('ex_getmore_title') ?? 'Get more coins',
              s?.get('ex_getmore_body') ?? 'Open the store to get more coins. Choose from different packs or, when available, watch ads to earn some for free.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'ex_withdraw',
        keyTarget: _kWithdrawGroup,
        shape: ShapeLightFocus.RRect,
        radius: 14,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => Common().bubble(
              s?.get('ex_withdraw_title') ?? 'Withdraw',
              s?.get('ex_withdraw_body') ??  'Choose a withdrawal option and follow the steps. Review limits, processing times and any applicable fees before confirming.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'ex_pending',
        keyTarget: _kPendingBalance,
        shape: ShapeLightFocus.RRect,
        radius: 14,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => Common().bubble(
              s?.get('ex_pending_title') ?? 'Pending balance',
              s?.get('ex_pending_body') ?? 'Withdrawals waiting to be transferred to their destination. Transfers are processed every 15 days: on the first business day of the month and the business day following the 15th.',
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _tryStartExchangeTutorial() async {
    final p = await SharedPreferences.getInstance();
    final pending = p.getBool(_PENDING_FLAG) ?? false;
    if (!pending) return;

    await _waitForTargetsReady();
    if (widget.controller.selectedIndexNotifier.value != 3) return;

    await _startExchangeTutorial();
  }

  Future<void> _startExchangeTutorial() async {
    LocalizedStrings? strings = LocalizedStrings.of(context);
    final targets = _buildExchangeTargets()
        .where((t) => t.keyTarget?.currentContext != null)
        .toList();

    if (targets.isEmpty) {
      await _clearPending();
      return;
    }

    _coach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      textSkip: strings!.get('tutorial_skip') ?? 'Skip tutorial',
      textStyleSkip: const TextStyle(fontWeight: FontWeight.w500 , fontSize: 20),
      hideSkip: false,
      useSafeArea: true,
      pulseEnable: true,
      alignSkip: Alignment.bottomRight,
      initialFocus: 0,
      disableBackButton: true,
      onClickOverlay: (_) {},
      onSkip: () {
        _clearPending();
        _markSeen();
        Common().markAllTutorialsSeen();
        return true;
      },
      onFinish: () async {

        await _clearPending();
        await _markSeen();

        final p = await SharedPreferences.getInstance();
        await p.setBool('__tutorial_pending__userinfo_v1', true);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.controller.updateIndex(4);
        });
        await Future.delayed(const Duration(milliseconds: 150));
      },
    );

    _coach!.show(context: context);
  }



  // --------- T U T O R I A L     M E T H O D S    -------------

  @override
  void initState() {
    super.initState();

    loadData();

    _tabListener = () async {
      if (widget.controller.selectedIndexNotifier.value == 3) {
        await loadData();
        _tryStartExchangeTutorial();
      }
    };
    widget.controller.selectedIndexNotifier.addListener(_tabListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.controller.selectedIndexNotifier.value == 3) {
        await loadData();
        _tryStartExchangeTutorial();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.selectedIndexNotifier.removeListener(_tabListener);
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
            Container(key: _kCoinsTag,
              child: Column(
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
                      ],
                    ),
                  ),
                  ElevatedButton(
                    key: _kGetMoreBtn,
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
              key: _kWithdrawGroup,
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
                          if (!canExchange){
                            Common().vibrate(300, 200);
                            setState(() => _isUserPointsHighlighted = true);
                            return;
                          }

                          if (!_isVerified){
                            showNotVerifiedDialog(context);
                            return;
                          }
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
                key: _kPendingBalance,
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
