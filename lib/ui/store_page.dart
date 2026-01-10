import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  const StorePage({
    super.key,
    this.preloadedBuyOptions,
    this.preloadedAdRewardOptions,
    this.preloadedCurrency,
    this.preloadedRewardPrize,
  });

  final List<Map<String, dynamic>>? preloadedBuyOptions;
  final List<Map<String, dynamic>>? preloadedAdRewardOptions;
  final String? preloadedCurrency;
  final int? preloadedRewardPrize;

  @override
  StorePageState createState() => StorePageState();
  
  /// Precarga los datos necesarios para StorePage antes de navegar
  static Future<Map<String, dynamic>> preloadStoreData() async {
    final prefs = await SharedPreferences.getInstance();
    final currency = (prefs.getBool('dollarCurrency') ?? false) ? 'usd' : 'eur';

    final buyOptionsResponse = await Common().postRequestWrapper(
      'Info',
      'StoreOptions',
      {'currency': currency, 'type': 'buy'},
    );

    final adRewardOptionsResponse = await Common().postRequestWrapper(
      'Info',
      'StoreOptions',
      {'currency': currency, 'type': 'ad_reward'},
    );

    final buyOptions = List<Map<String, dynamic>>.from(buyOptionsResponse['body'] as Iterable);
    final adRewardOptions = List<Map<String, dynamic>>.from(adRewardOptionsResponse['body'] as Iterable);
    
    // Calcular rewardPrize
    int rewardPrize = 15;
    if (adRewardOptions.isNotEmpty) {
      final coinsValue = adRewardOptions[0]['coins'];
      if (coinsValue != null) {
        if (coinsValue is int) {
          rewardPrize = coinsValue;
        } else if (coinsValue is double) {
          rewardPrize = coinsValue.toInt();
        } else if (coinsValue is String) {
          rewardPrize = int.tryParse(coinsValue) ?? 15;
        }
      }
    }

    return {
      'buyOptions': buyOptions,
      'adRewardOptions': adRewardOptions,
      'currency': currency,
      'rewardPrize': rewardPrize,
    };
  }
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
  Timer? _autoScrollTimer;
  int? _rewardPrize;
  final Map<int, GlobalKey<_StoreSliderState>> _sliderKeys = {};

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
    
    // Si hay datos precargados, usarlos inmediatamente
    if (widget.preloadedBuyOptions != null && 
        widget.preloadedAdRewardOptions != null) {
      setState(() {
        _buyOptions = widget.preloadedBuyOptions!;
        _adRewardOptions = widget.preloadedAdRewardOptions!;
        if (widget.preloadedCurrency != null) {
          _currency = widget.preloadedCurrency!;
        }
        if (widget.preloadedRewardPrize != null) {
          _rewardPrize = widget.preloadedRewardPrize!;
        }
      });
      // Iniciar el timer de autoscroll cuando hay datos precargados
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _startRandomAutoScroll();
          }
        });
      });
    } else {
      // Si no hay datos precargados, cargar normalmente
      loadData();
    }
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        loadData();
      }
    });
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _progressController.dispose();
    _refreshTimer?.cancel();
    _autoScrollTimer?.cancel();
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

    // Verificar que el widget sigue montado antes de actualizar el estado
    if (!mounted) return;

    setState(() {
      _buyOptions =
      List<Map<String, dynamic>>.from(buyOptionsResponse['body'] as Iterable);
      _adRewardOptions = List<Map<String, dynamic>>.from(
          adRewardOptionsResponse['body'] as Iterable);
      
      debugPrint('StorePage loadData: _adRewardOptions recibidas: $_adRewardOptions');
      
      // Obtener el premio de las opciones de recompensa
      if (_adRewardOptions.isNotEmpty) {
        final coinsValue = _adRewardOptions[0]['coins'];
        debugPrint('StorePage loadData: coinsValue del primer elemento: $coinsValue (tipo: ${coinsValue.runtimeType})');
        if (coinsValue != null) {
          // Manejar diferentes tipos: int, double, o string
          if (coinsValue is int) {
            _rewardPrize = coinsValue;
          } else if (coinsValue is double) {
            _rewardPrize = coinsValue.toInt();
          } else if (coinsValue is String) {
            _rewardPrize = int.tryParse(coinsValue) ?? 15;
          } else {
            _rewardPrize = 15;
          }
        } else {
          _rewardPrize = 15;
        }
      } else {
        _rewardPrize = 15;
      }
      debugPrint('StorePage loadData: _rewardPrize establecido a: $_rewardPrize');
    });
    
    // Limpiar keys obsoletas si el número de opciones cambió
    final newCount = _buyOptions.length;
    _sliderKeys.removeWhere((key, value) => key >= newCount);
    
    // Reiniciar el timer de autoscroll después de cargar los datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _startRandomAutoScroll();
        }
      });
    });
  }

  /// Inicia el timer de autoscroll aleatorio para los sliders
  void _startRandomAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        return;
      }

      // Filtrar solo los sliders que están montados
      final availableSliders = _sliderKeys.entries
          .where((entry) => entry.value.currentState != null && entry.value.currentState!.mounted)
          .toList();

      if (availableSliders.isEmpty) return;

      // Seleccionar un slider aleatorio
      final random = DateTime.now().millisecondsSinceEpoch % availableSliders.length;
      final selectedSlider = availableSliders[random];

      // Ejecutar autoscroll en el slider seleccionado
      selectedSlider.value.currentState?.triggerAutoSlide();
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
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _loadRewardedAd();
                }
              });
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
    int? coins,
  }) async {
    final url =
    Uri.parse("https://${Config.publicDomain}/api/Rewards/RequestAdNonce");

    final payload = {
      'adUnitId': adUnitId,
      if (purpose != null) 'purpose': purpose,
      if (coins != null) 'coins': coins,
    };

    debugPrint('StorePage requestRewardNonce: Enviando payload: $payload');

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
      debugPrint('StorePage requestRewardNonce: Respuesta del servidor: $data');
      return nonce;
    }

    debugPrint('StorePage requestRewardNonce: Error ${res.statusCode}: $body');
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

      // Asegurar que tenemos el valor correcto de la recompensa
      final rewardCoins = _rewardPrize ?? (_adRewardOptions.isNotEmpty 
          ? (_adRewardOptions[0]['coins'] as num?)?.toInt() ?? 15 
          : 15);
      
      debugPrint('StorePage: Enviando recompensa de $rewardCoins coins al backend');
      
      final nonce = await requestRewardNonce(
        userId: userId,
        adUnitId: adId,
        purpose: 'store_page_reward',
        coins: rewardCoins,
      );

      if (!mounted) return;

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
      if (!mounted) return;
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
        if (!mounted) return;
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
        Key? key,
        required int coins,
        required double price,
        required VoidCallback onPressed,
        required Color color,
        required double k,
      }) {
    return _StoreSlider(
      key: key,
      coins: coins,
      price: price,
      color: color,
      k: k,
      currency: _currency,
      onSlideComplete: onPressed,
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
          style: GoogleFonts.syncopate(fontSize: 24, fontWeight: FontWeight.w400),
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
                    final scales = [1.20, 1.28, 1.33, 1.37];

                    // Crear o obtener la key para este slider
                    if (!_sliderKeys.containsKey(index)) {
                      _sliderKeys[index] = GlobalKey<_StoreSliderState>();
                    }

                    return _buildStoreButton(
                      context,
                      strings,
                      key: _sliderKeys[index],
                      coins: coins,
                      price: price,
                      color: index < colors.length ? colors[index] : Colors.blueGrey,
                      k: index < scales.length ? scales[index] : 1.0,
                      onPressed: () {
                        _cardPayment(coins.toDouble(), price);
                      },
                    );
                  }),
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(vertical: 8),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.ccVisa,
                        color: Colors.white,
                        size: 35,
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        FontAwesomeIcons.ccMastercard,
                        color: Colors.white,
                        size: 35,
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        FontAwesomeIcons.ccApplePay,
                        color: Colors.white,
                        size: 35,
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        FontAwesomeIcons.ccPaypal,
                        color: Colors.white,
                        size: 35,
                      ), 
                      const SizedBox(width: 20),
                      Icon(
                        FontAwesomeIcons.ccAmazonPay,
                        color: Colors.white,
                        size: 35,
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 120),
                  height: 0.5,
                  color: Colors.white,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'powered by',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Image.asset(
                        'assets/stripe.png',
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_rewardPrize != null) ...[
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withAlpha(50),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return LinearProgressIndicator(
                                  minHeight: 60,
                                  value: _adPermanentlyDisabled
                                      ? 0
                                      : (_isAdLoaded ? 1 : _progressController.value),
                                  backgroundColor: _adPermanentlyDisabled
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade900,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _adPermanentlyDisabled
                                        ? Colors.grey.shade600
                                        : Colors.deepPurple,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: (_isAdLoaded && !_adPermanentlyDisabled)
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
                                : () {
                                    Common().showFloatingSnack(
                                      context,
                                      strings.get('noAdsAvailableNow') ??
                                          "No ads available right now!",
                                    );
                                  },
                            borderRadius: BorderRadius.circular(16),
                            splashColor: Colors.white24,
                            highlightColor: Colors.white12,
                            child: Container(
                              height: 60,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 0.0),
                              child: Stack(
                                children: [
                                  // Texto centrado
                                  Center(
                                    child: Text(
                                      (strings.get('earnCoins') ??
                                              'Watch an Ad to Earn {coins}')
                                          .replaceAll(RegExp(r'\{coins\}'), '')
                                          .trim(),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withAlpha(100),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  // Icono posicionado a la izquierda, centrado verticalmente
                                  Positioned(
                                    left: 30,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(0),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(30),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.play_circle_filled,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Cantidad de monedas con icono a la derecha, centrado verticalmente
                                  Positioned(
                                    right: 30,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _rewardPrize.toString(),
                                            style: GoogleFonts.montserrat(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withAlpha(100),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.all(0),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent.withAlpha(0),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Image.asset(
                                              'assets/coin.png',
                                              width: 26,
                                              height: 26,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white70,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreSlider extends StatefulWidget {
  final int coins;
  final double price;
  final Color color;
  final double k;
  final String currency;
  final VoidCallback onSlideComplete;

  const _StoreSlider({
    super.key,
    required this.coins,
    required this.price,
    required this.color,
    required this.k,
    required this.currency,
    required this.onSlideComplete,
  });

  @override
  State<_StoreSlider> createState() => _StoreSliderState();
}

class _StoreSliderState extends State<_StoreSlider> with SingleTickerProviderStateMixin {
  double _sliderValue = 0.0;
  bool _isPressed = false;
  late AnimationController _autoSlideController;
  late Animation<double> _autoSlideAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _autoSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Crear animación que va a 0.15, rebota un poco y vuelve a 0
    _autoSlideAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.15, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 0.5,
      )
      
    ]).animate(_autoSlideController);

    _autoSlideAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _sliderValue = _autoSlideAnimation.value;
        });
      }
    });
  }

  /// Método público para activar la animación de autoslide
  /// Puede ejecutarse múltiples veces
  void triggerAutoSlide() {
    if (_isAnimating || !mounted) return;
    
    _isAnimating = true;
    _autoSlideController.reset();
    _autoSlideController.forward().then((_) {
      if (mounted) {
        _autoSlideController.reset();
        setState(() {
          _sliderValue = 0.0;
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoSlideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Container(
        height: 60 * widget.k + 24,
        decoration: BoxDecoration(
          color: Colors.transparent.withAlpha(30),
          borderRadius: BorderRadius.circular(50.0),
          boxShadow: [
            BoxShadow(
              color: widget.color.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Flecha hacia la derecha (se oculta cuando se desliza) - centrada en el slider
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 1.0 - (_sliderValue * 1.5).clamp(0.0, 1.0),
                  child: Icon(
                    Icons.double_arrow,
                    size: 35 * widget.k,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
            // Fondo: Contenedor de monedas (bet-coins) - fondo fijo a la derecha
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Contenedor de monedas (bet-coins) (derecha) - fondo fijo
                    Container(
                      width: 90 * widget.k,
                      height: 70 * widget.k,
                      margin: const EdgeInsets.only(left: 6.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.color,
                            widget.color.withAlpha(200),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(60.0),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withAlpha(80),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/coin.png',
                            width: 35 * widget.k,
                            height: 28 * widget.k,
                          ),
                          Text(
                            '${widget.coins}',
                            style: GoogleFonts.syncopate(
                              fontSize: 15 * widget.k,
                              fontWeight: FontWeight.w200,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha(120),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ), 
            ),
            // Primer plano: Contenedor de precio que se desliza desde la izquierda
            LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                // Ancho igual al contenedor fijo de monedas
                final containerWidth = 100.0 * widget.k;
                // Calcular el offset: cuando sliderValue es 0, está completamente a la izquierda
                // Cuando sliderValue es 1, se mueve completamente a la derecha
                final paddingHorizontal = 8.0;
                final maxOffset = totalWidth - containerWidth - (paddingHorizontal * 2);
                final slideOffset = maxOffset * _sliderValue;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: Offset(slideOffset, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60.0),
                        child: SizedBox(
                          width: containerWidth,
                          height: 70 * widget.k,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: containerWidth,
                              minWidth: containerWidth,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _isPressed
                                    ? [
                                        Colors.white.withAlpha(80),
                                        Colors.white.withAlpha(50),
                                      ]
                                    : [
                                        Colors.white.withAlpha(30),
                                        Colors.white.withAlpha(15),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(60.0),
                              border: Border.all(
                                color: _isPressed
                                    ? Colors.white.withAlpha(120)
                                    : Colors.white.withAlpha(50),
                                width: _isPressed ? 2.0 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _isPressed
                                      ? Colors.white.withAlpha(100)
                                      : Colors.black.withAlpha(60),
                                  blurRadius: _isPressed ? 12 : 8,
                                  offset: const Offset(0, 3),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    widget.currency == 'eur' ? 'assets/euro.png' : 'assets/dollar.png',
                                    width: 28 * widget.k,
                                    height: 28 * widget.k,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.price.toStringAsFixed(2),
                                    style: GoogleFonts.syncopate(
                                      fontSize: 16 * widget.k,
                                      fontWeight: FontWeight.w200,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withAlpha(120),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),                     ),
                  ),
                );
              },
            ),
            // Slider invisible para capturar gestos
            Positioned.fill(
              child: SliderTheme(
                data: SliderThemeData(
                  trackShape: const _StoreSliderTrackShape(),
                  thumbShape: const _StoreSliderThumbShape(),
                  trackHeight: 0,
                  thumbColor: Colors.transparent,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  overlayShape: SliderComponentShape.noOverlay,
                  overlayColor: Colors.transparent,
                ),
                child: Slider(
                  value: _sliderValue,
                  onChanged: (value) {
                    _autoSlideController.stop();
                    _autoSlideController.reset();
                    setState(() {
                      _sliderValue = value;
                      _isPressed = true;
                    });
                  },
                  onChangeStart: (_) {
                    _autoSlideController.stop();
                    _autoSlideController.reset();
                    setState(() => _isPressed = true);
                  },
                  onChangeEnd: (value) {
                    setState(() => _isPressed = false);
                    if (value > 0.9) {
                      setState(() => _sliderValue = 1.0);
                      widget.onSlideComplete();
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) setState(() => _sliderValue = 0.0);
                      });
                    } else {
                      setState(() => _sliderValue = 0.0);
                    }
                  },
                  min: 0.0,
                  max: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreSliderTrackShape extends SliderTrackShape {
  const _StoreSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      parentBox.size.width,
      0,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    // No pintar nada, el track es transparente
  }
}

class _StoreSliderThumbShape extends SliderComponentShape {
  const _StoreSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(0, 0);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required Size sizeWithOverflow,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double textScaleFactor,
    required double value,
  }) {
    // No pintar nada, el thumb es invisible
  }
}
