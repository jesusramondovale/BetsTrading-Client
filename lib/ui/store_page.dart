import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/bets_service.dart';
import '../config/config.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import 'layout_page.dart';

/// A page for purchasing coins and viewing ad reward options.
///
/// Displays buy options with Stripe integration and ad reward opportunities.
/// Manages rewarded ad loading and display for earning coins.
class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  StorePageState createState() => StorePageState();
}

class StorePageState extends State<StorePage> with TickerProviderStateMixin {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _loadingAd = false;
  bool _showingAd = false;
  int _loadRetry = 0;
  bool _adPermanentlyDisabled = false;

  String _currency = 'eur';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late AnimationController _progressController;
  List<Map<String, dynamic>> _buyOptions = [];
  List<Map<String, dynamic>> _adRewardOptions = [];
  Timer? _refreshTimer;
  int? _rewardPrize;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      upperBound: 0.9,
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
    MobileAds.instance.initialize();
    _loadRewardedAd();
    loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      loadData();
    });
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _progressController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('dollarCurrency') ?? false) {
      _currency = 'usd';
    }

    final buyOptionsResponse = await Common().postRequestWrapper(
      'Info',
      'StoreOptions',
      {'currency': _currency, 'type': 'buy'},
    );

    final adRewardOptionsResponse = await Common().postRequestWrapper(
      'Info',
      'StoreOptions',
      {'currency': _currency, 'type': 'ad_reward'},
    );

    setState(() {
      _buyOptions =
      List<Map<String, dynamic>>.from(buyOptionsResponse['body'] as Iterable);
      _adRewardOptions = List<Map<String, dynamic>>.from(
          adRewardOptionsResponse['body'] as Iterable);
      _rewardPrize = _adRewardOptions.isNotEmpty
          ? (_adRewardOptions[0]['coins'] ?? 15) as int
          : 15;
    });
  }

  void _loadRewardedAd() {
    if (_loadingAd || _rewardedAd != null) return;
    _loadingAd = true;
    _isAdLoaded = false;
    if (mounted) setState(() {});

    RewardedAd.load(
      adUnitId: Config.admobAdToken,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loadingAd = false;
          _loadRetry = 0;
          _isAdLoaded = true;
          _progressController.value = 1;
          if (mounted) setState(() {});

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isAdLoaded = false;
              if (mounted) setState(() {});
              Future.delayed(const Duration(milliseconds: 500), _loadRewardedAd);
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _rewardedAd = null;
              _isAdLoaded = false;
              if (mounted) setState(() {});
              _loadRetry = (_loadRetry + 1).clamp(0, 5);
              debugPrint('Rewarded failed to show: $err');
            },
          );
        },

        onAdFailedToLoad: (error) {
          _loadingAd = false;
          _adPermanentlyDisabled = true;
          _isAdLoaded = false;
          if (mounted) setState(() {});
          _loadRetry = (_loadRetry + 1).clamp(0, 5);
          debugPrint('Rewarded load failed: $error');
        },

      ),
    );

  }

  Future<String> requestRewardNonce({
    required String userId,
    required String adUnitId,
    String? purpose,
  }) async {
    final url =
    Uri.parse("https://${Config.publicDomain}/api/Rewards/RequestAdNonce");

    final payload = {
      'adUnitId': adUnitId,
      if (purpose != null) 'purpose': purpose,
    };

    final client = HttpClient();
    final req = await client.postUrl(url);
    req.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
    req.headers.add('X-UserId', userId);

    final jwtToken = await _storage.read(key: 'jwtToken');
    if (jwtToken != null && jwtToken.isNotEmpty) {
      req.headers.set('Authorization', 'Bearer $jwtToken');
    }

    final jsonBody = jsonEncode(payload);
    req.add(utf8.encode(jsonBody));

    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();

    if (res.statusCode == 200) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final nonce = data['nonce'] as String?;
      if (nonce == null || nonce.isEmpty) {
        throw Exception('Nonce vacío del servidor');
      }
      return nonce;
    }

    throw Exception('requestRewardNonce failed: ${res.statusCode} $body');
  }

  Future<void> _showRewardedAd(String localizedWarning) async {
    if (_showingAd) return;
    if (_rewardedAd == null) {
      Common().showFloatingSnack(
        context,
        LocalizedStrings.of(context)!.get('loadingAdTrySoon') ??  'Loading ad… try again in a few seconds',
      );
      _loadRewardedAd();
      return;
    }

    _showingAd = true;
    final ad = _rewardedAd!;
    final dismissed = Completer<void>();
    final prevCb = ad.fullScreenContentCallback;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (a) {
        try { prevCb?.onAdShowedFullScreenContent?.call(a); } catch (_) {}
      },
      onAdImpression: (a) {
        try { prevCb?.onAdImpression?.call(a); } catch (_) {}
      },
      onAdWillDismissFullScreenContent: (a) {
        try { prevCb?.onAdWillDismissFullScreenContent?.call(a); } catch (_) {}
      },
      onAdDismissedFullScreenContent: (a) {
        try { prevCb?.onAdDismissedFullScreenContent?.call(a); } catch (_) {}
        if (!dismissed.isCompleted) dismissed.complete();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        try { prevCb?.onAdFailedToShowFullScreenContent?.call(a, err); } catch (_) {}
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );

    try {
      final userId = await _storage.read(key: 'sessionToken');
      final adId = Config.admobAdToken;
      if (userId == null || !mounted) return;

      final nonce = await requestRewardNonce(
        userId: userId,
        adUnitId: adId,
        purpose: 'store_page_reward',
      );

      ad.setServerSideOptions(ServerSideVerificationOptions(
        userId: userId,
        customData: nonce,
      ));

      num earned = 0;
      await ad.show(onUserEarnedReward: (_, reward) {
        earned = reward.amount;
      });

      await dismissed.future;

      if (earned > 0) {
        await BetsService().getUserInfo(userId);
        if (!mounted) return;
        Navigator.pop(context);
        Common().showFloatingSnack(context, localizedWarning, showIcon: true);
        homeScreenKey.currentState?.loadUserIdAndData();
        awardsScreenKey.currentState?.loadUserIdAndData();

      }
    } catch (e) {
      debugPrint('show rewarded error: $e');
    } finally {
      _showingAd = false;
    }
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
            currencyCode: _currency.toUpperCase(),
          ),
        ),
      );
      await stripe.Stripe.instance.presentPaymentSheet();
      await BetsService().getUserInfo(userId);
      Navigator.pop(context);
      homeScreenKey.currentState?.loadUserIdAndData();
      awardsScreenKey.currentState?.loadUserIdAndData();
      Common().showFloatingSnack(
        context,
        Common().interpolate(
          LocalizedStrings.of(context)!.get('youEarnedCoins') ?? 'You earned {coins}',
          {'coins': coins.toStringAsFixed(0)},
        ),
        showIcon: true,
      );
    } on stripe.StripeException catch (e) {
      if (e.error.code != stripe.FailureCode.Canceled) {
        Navigator.pop(context);
        Common().showFloatingSnack(
          context,
          LocalizedStrings.of(context)!.get('transactionError') ??
              "Error during transaction process!",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<String> _getClientSecret(double price, String userId, double coins) async {
    final requestData = {
      'amount': (price * 100).toInt(),
      'currency': _currency,
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
                      (_currency == 'eur' ? '{price}€' : '{price}\$'),
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
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator(color: Colors.grey)),
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
                  }),
                const Spacer(),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_rewardPrize != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              minHeight: 56,
                              value: _adPermanentlyDisabled
                                  ? 0
                                  : (_isAdLoaded ? 1 : _progressController.value),
                              backgroundColor: _adPermanentlyDisabled
                                  ? Colors.grey
                                  : Colors.grey.shade800,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _adPermanentlyDisabled ? Colors.grey : Colors.purple,
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: _adPermanentlyDisabled
                              ? Colors.grey
                              : Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: (_isAdLoaded && !_adPermanentlyDisabled)
                            ? () {
                          Common().vibrate();
                          Common().applyImmersive();
                          _showRewardedAd(
                            Common().interpolate(
                              strings.get('youWonCoins') ?? 'You won {coins}',
                              {'coins': _rewardPrize.toString()},
                            ),
                          );
                        }
                            : () { Common().showFloatingSnack(context, strings.get('noAdsAvailableNow') ?? "No ads available right now!");},
                        icon: const Icon(Icons.ondemand_video, size: 34),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Common().interpolate(
                                strings.get('earnCoins') ??
                                    'Watch an Ad to Earn {coins}',
                                {'coins': _rewardPrize.toString()},
                              ),
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset('assets/coin.png', width: 30, height: 30),
                          ],
                        ),
                      )
                    ] else ...[
                      const Center(child: CircularProgressIndicator(color: Colors.grey))
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
