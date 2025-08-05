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
import '../native_rewarded.dart';
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

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      upperBound: 0.9,
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent.withValues(alpha: 0.0),
          automaticallyImplyLeading: true,
          title: Text(
            strings!.get('store') ?? 'Store',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        body: Stack(
          children: [
            // Fondo
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

            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 90.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStoreButton(
                    context,
                    strings,
                    coins: 100,
                    price: 1.99,
                    color: Colors.brown,
                    k: 1,
                    onPressed: () {
                      _cardPayment(100, 1.99);
                    },
                  ),
                  _buildStoreButton(
                    context,
                    strings,
                    coins: 500,
                    price: 7.99,
                    color: Colors.grey,
                    k: 1.15,
                    onPressed: () {
                      _cardPayment(500, 7.99);
                    },
                  ),
                  _buildStoreButton(
                    context,
                    strings,
                    coins: 1000,
                    price: 14.99,
                    color: Colors.amber,
                    k: 1.25,
                    onPressed: () {
                      _cardPayment(1000, 14.99);
                    },
                  ),
                  _buildStoreButton(
                    context,
                    strings,
                    coins: 5000,
                    price: 59.99,
                    color: Colors.deepPurple,
                    k: 1.35,
                    onPressed: () {
                      _cardPayment(5000, 59.99);
                    },
                  ),
                  const Spacer(),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              value:
                                  _isAdLoaded ? 1 : _progressController.value,
                              minHeight: 56,
                              backgroundColor: Colors.grey.shade800,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.purple),
                            );
                          },
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 56),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isAdLoaded
                            ? () {
                                Common().vibrate(40, 30);
                                _showRewardedAd(
                                    50,
                                    Common().interpolate(
                                        strings.get('youWonCoins') ??
                                            'You won 50',
                                        {
                                          'coins': 50.toString() + '🪙',
                                        }));
                              }
                            : null,
                        icon: Icon(Icons.ondemand_video, size: 34),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Common().interpolate(
                                strings.get('earnCoins') ??
                                    'Watch an Ad to Earn {coins}🪙',
                                {
                                  'coins': '50',
                                },
                              ),
                              style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              'assets/coin.png',
                              width: 18,
                              height: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: Config.ADMOB_AD_TOKEN_TEST,
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

  Future<void> _showRewardedAd(double coins, String localizedWarning) async {
    String? userId = await _storage.read(key: 'sessionToken');
    if (userId == null) return;
    try {
      await NativeRewarded.loadRewarded(Config.ADMOB_AD_TOKEN_TEST, userId);
      final reward = await NativeRewarded.showRewarded();
      await AuthService().addCoins(userId, coins);
      if (reward != null && reward > 0) {
        Common().showLocalNotification(
          "other",
          "Betrader",
          localizedWarning,
          {"REWARD": reward},
        );
        await BetsService().getUserInfo(userId);
        Navigator.pop(context);
        homeScreenKey.currentState?.loadUserIdAndData();
      }
    } catch (e) {
      print('Error mostrando anuncio recompensado: $e');
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
      color: Colors.transparent, // Permite el splash
      borderRadius: BorderRadius.circular(50.0),
      child: InkWell(
        onTap: onPressed,
        splashColor: Colors.white24,
        highlightColor: Colors.white12,
        borderRadius: BorderRadius.circular(50.0),
        child: Card(
          color: Colors.transparent.withValues(alpha: .1),
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
                      fontSize: 20.0,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    Common().interpolate(
                      strings.get('priceInEuros') ?? '€{price}',
                      {'price': price.toStringAsFixed(2)},
                    ),
                    style: GoogleFonts.roboto(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w400,
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
            state: 'Asturias'),
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
      Common().showLocalNotification(
        "other",
        "Betrader",
        Common().interpolate(
            LocalizedStrings.of(context)!.get('youEarnedCoins') ??
                'You earned ${coins}🪙!',
            {'coins': coins.toString()}),
        {"REWARD": coins},
      );
    } on stripe.StripeException catch (e) {
      if (e.error.code != stripe.FailureCode.Canceled) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 3),
            content: Text("Error during transaction process!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _getClientSecret(
      double price, String userId, double coins) async {
    final Map<String, dynamic> requestData = {
      'amount': (price * 100).toInt(),
      'currency': "eur",
      'userId': userId,
      'coins': coins,
    };
    final response = await Common().postRequestWrapper(
      'Payments',
      'CreatePaymentIntent',
      requestData,
    );
    if (response['statusCode'] == 200 &&
        response['body'] != null &&
        response['body']['client_secret'] != null) {
      return response['body']['client_secret'];
    } else {
      throw Exception('Error al obtener client_secret desde el backend');
    }
  }
}
