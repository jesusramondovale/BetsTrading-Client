import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../Services/BetsService.dart';
import '../config/config.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import '../services/AuthService.dart';
import 'layout_page.dart';

class StorePage extends StatefulWidget {
  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> with TickerProviderStateMixin {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late AnimationController _progressController;
  List<Map<String, dynamic>> _buyOptions = [];
  List<Map<String, dynamic>> _adRewardOptions = [];
  Timer? _refreshTimer;
  int? _rewardPrize;

  Future<void> loadData() async {
    final currency = await _storage.read(key: 'currency') ?? 'eur'; //TODO
    final buyOptionsResponse = await Common().postRequestWrapper('Info', 'StoreOptions', {'currency': currency, 'type' : 'buy'});
    final adRewardOptionsResponse = await Common().postRequestWrapper('Info', 'StoreOptions', {'currency': 'eur', 'type': 'ad_reward'}); //TODO Currency



    setState(() {
      _buyOptions = List<Map<String, dynamic>>.from(buyOptionsResponse['body'] as Iterable);
      _adRewardOptions = List<Map<String, dynamic>>.from(adRewardOptionsResponse['body'] as Iterable);
      _rewardPrize = _adRewardOptions[0]['coins'] ?? 50;
    });
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: Config.ADMOB_AD_TOKEN_TEST, //TODO
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
            _progressController.value = 1;
          });
        },
        onAdFailedToLoad: (error) {
          print('Error loading ad: $error');
        },
      ),
    );
  }

  Future<void> _cardPayment(double coins, double price) async {
    try {
      String? userId = await _storage.read(key: 'sessionToken');
      final billingDetails = stripe.BillingDetails(
        email: 'betsontrading@gmail.com',
        phone: '',
        address: stripe.Address(
          city: 'Carreño',
          country: 'ES',
          line1: '',
          line2: '',
          postalCode: '33430',
          state: 'Asturias',
        ),
      );
      final clientSecret = await _getClientSecret(price, userId!, coins);
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.dark,
          merchantDisplayName: 'Betrader',
          billingDetails: billingDetails,
          googlePay: stripe.PaymentSheetGooglePay(
            merchantCountryCode: 'ES',
            currencyCode: 'EUR',
          ),
        ),
      );
      await stripe.Stripe.instance.presentPaymentSheet();
      await BetsService().getUserInfo(userId);
      Navigator.pop(context);
      homeScreenKey.currentState?.loadUserIdAndData();
      Common().showFloatingSnack(
          context,
          Common().interpolate(LocalizedStrings.of(context)!.get('youEarnedCoins') ?? 'You earned {coins}',
            {'coins': coins.toStringAsFixed(0)},), showIcon: true);

    } on stripe.StripeException catch (e) {
      if (e.error.code != stripe.FailureCode.Canceled) {
        Navigator.pop(context);
        Common().showFloatingSnack(context, LocalizedStrings.of(context)!.get('transactionError') ?? "Error during transaction process!", backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _showRewardedAd(int coins, String localizedWarning) async {
    final userId = await _storage.read(key: 'sessionToken');
    if (userId == null) return;

    try {
      await RewardedAd.load(
        adUnitId: Config.ADMOB_AD_TOKEN_TEST, //TODO
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) async {
            final dismissed = Completer<void>();
            num earned = 0;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!dismissed.isCompleted) dismissed.complete(); // <- CERRADO
              },
              onAdFailedToShowFullScreenContent: (ad, err) {
                ad.dispose();
                if (!dismissed.isCompleted) dismissed.complete();
              },
            );

            await ad.show(onUserEarnedReward: (ad, reward) {
              earned = reward.amount;
            });

            await dismissed.future;

            if (earned > 0) {
              await AuthService().addCoins(userId, coins); // TODO: remove addCoins call
              await BetsService().getUserInfo(userId);
              if (!mounted) return;
              Navigator.pop(context);
              Common().showFloatingSnack(context, localizedWarning, showIcon: true); // <- tras cierre
              homeScreenKey.currentState?.loadUserIdAndData();
            }
          },
          onAdFailedToLoad: (LoadAdError e) {
            print('Error mostrando anuncio recompensado: $e');
          },
        ),
      );
    } catch (e) {
      print('Error mostrando anuncio recompensado: $e');
    }
  }

  Future<String> _getClientSecret(double price, String userId, double coins) async {
    final requestData = {
      'amount': (price * 100).toInt(),
      'currency': "eur",
      'userId': userId,
      'coins': coins,
    };
    final response = await Common().postRequestWrapper('Payments', 'CreatePaymentIntent', requestData);
    if (response['statusCode'] == 200 &&
        response['body'] != null &&
        response['body']['client_secret'] != null) {
      return response['body']['client_secret'];
    } else {
      throw Exception('Error al obtener client_secret desde el backend');
    }
  }

  Widget _buildStoreButton(
      BuildContext context,
      LocalizedStrings strings, {
        required int coins,
        required double price,
        required VoidCallback onPressed,
        required Color color,
        required double k,
      }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(50.0),
      child: InkWell(
        onTap: onPressed,
        splashColor: Colors.white24,
        highlightColor: Colors.white12,
        borderRadius: BorderRadius.circular(50.0),
        child: Card(
          color: Colors.transparent.withAlpha(25),
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60 * k,
                  height: 60 * k,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  margin: EdgeInsets.fromLTRB(12 / 4 * k, 0, 12, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/coin.png',
                        width: 20 * k,
                        height: 20 * k,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$coins',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    Common().interpolate(
                      strings.get('buyCoins') ?? 'Buy {coins} Coins',
                      {'coins': coins.toString()},
                    ),
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w200,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    Common().interpolate(
                      strings.get('priceInEuros') ?? '{price}',
                      {'price': price.toStringAsFixed(2)},
                    ),
                    style: GoogleFonts.syncopate(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      upperBound: 0.9,
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
    _loadRewardedAd();
    loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      loadData();
      _loadRewardedAd();
    });
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _progressController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent.withAlpha(0),
        automaticallyImplyLeading: true,
        title: Text(
          strings!.get('store') ?? 'Store',
          style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w400),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/android12splash.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withAlpha(50)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 90.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_buyOptions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.grey)
                    ),
                  )
                else
                  ..._buyOptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    final double price = (item['euros'] ?? 0).toDouble();
                    final int coins = (item['coins'] ?? 0) as int;

                    final colors = [Colors.brown, Colors.grey, Colors.amber, Colors.deepPurple];
                    final scales = [1.0, 1.15, 1.25, 1.35];

                    return _buildStoreButton(
                      context,
                      strings,
                      coins: coins,
                      price: price,
                      color: index < colors.length ? colors[index] : Colors.blueGrey,
                      k: index < scales.length ? scales[index] : 1.0,
                      onPressed: () {
                        _cardPayment(coins.toDouble(), price);
                      },
                    );
                  }).toList(),
                const Spacer(),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_rewardPrize != null) ...
                    [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _isAdLoaded ? 1 : _progressController.value,
                                minHeight: 56,
                                backgroundColor: Colors.grey.shade800,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                              );
                            },
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isAdLoaded
                              ? () {
                            Common().vibrate(40, 30);
                            _showRewardedAd(
                              _rewardPrize ?? 15,
                              Common().interpolate(
                                strings.get('youWonCoins') ?? 'You won {coins}',
                                {'coins': _rewardPrize.toString()}, //TODO
                              ),
                            );
                          }
                              : null,
                          icon: const Icon(Icons.ondemand_video, size: 34),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                Common().interpolate(
                                  strings.get('earnCoins') ?? 'Watch an Ad to Earn {coins}🪙',
                                  {'coins': _rewardPrize.toString()},
                                ),
                                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Image.asset('assets/coin.png', width: 18, height: 18),
                            ],
                          ),
                        )
                    ]
                    else ...
                    [
                      Center(
                        child: CircularProgressIndicator(color: Colors.grey)
                      )
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
