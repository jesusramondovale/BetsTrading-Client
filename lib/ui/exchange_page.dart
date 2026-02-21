import 'dart:async';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/ui/store_page.dart';
import 'package:betrader/ui/verify_account_page.dart';
import 'package:betrader/ui/withdraw_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../helpers/common.dart';
import 'exchange_slider_shapes.dart';
import 'first_time_page.dart';
import 'layout_page.dart';

/// A page for exchanging coins to currency and managing withdrawals.
///
/// Displays user balance, pending balance, exchange options, and provides
/// navigation to withdrawal and verification pages.
class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key, required this.controller});
  
  /// Controller for managing the main menu navigation.
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
  bool _isLoadingStore = false;
  final Set<int> _loadingSliders = {};
  final _kCoinsTag        = GlobalKey();
  final _kGetMoreBtn      = GlobalKey();
  final _kWithdrawGroup   = GlobalKey();
  final _kPendingBalance  = GlobalKey();
  static const String _pendingFlag = '__tutorial_pending__exchange_v1';
  static const String _seenFlag    = '__tutorial_seen__exchange_v1';
  TutorialCoachMark? _coach;
  late final VoidCallback _tabListener;
  final Map<int, GlobalKey<_ExchangeSliderState>> _sliderKeys = {};
  Timer? _autoScrollTimer;



  /// Loads exchange page data including user points, verification status,
  /// pending balance, and available exchange options.
  Future<void> loadData() async {
    final userId = await _storage.read(key: 'sessionToken') ?? '';
    final points = await _storage.read(key: 'points') ?? '0';
    final isVerified = await _storage.read(key: 'isverified');
    final pendingBalanceResponse = await Common().postRequestWrapper('Info', 'PendingBalance', {});
    final exchangeOptionsResponse = await Common().postRequestWrapper('Info', 'StoreOptions', {'currency': _currency, 'type': 'exchange'});
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
        _userId = userId;
        _userPoints = points;
        _isVerified = isVerified == "true";
        _pendingBalance = pendingBalanceResponse['body']['balance']?.toDouble() ?? 0.0;
        if (pendingBalanceResponse['statusCode'] == 201){ // PASSWORD NOT SET
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const FirstTimePage()));

        }
        final newExchangeOptions = List<Map<String, dynamic>>.from(exchangeOptionsResponse['body'] as Iterable);
        _exchangeOptions = newExchangeOptions;
        
        // Limpiar keys obsoletas si el número de opciones cambió
        final newCount = newExchangeOptions.length;
        _sliderKeys.removeWhere((key, value) => key >= newCount);
        
        if (prefs.getBool('dollarCurrency') ?? false){
          _currency = 'usd';
        }
  });
  
  // Reiniciar el timer de autoscroll si estamos en el tab correcto
  if (mounted && widget.controller.selectedIndexNotifier.value == 3) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _startRandomAutoScroll();
        }
      });
    });
  }
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
    await p.setBool(_seenFlag, true);
  }

  Future<void> _clearPending() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_pendingFlag);
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
    final pending = p.getBool(_pendingFlag) ?? false;
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

        // Esperar un poco más para asegurar que el tutorial se cierre completamente
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (!mounted) return;
        
        // Cambiar a la pestaña 4 y dar tiempo para que se inicialice
        widget.controller.updateIndex(4);
        
        // Dar tiempo adicional para que UserInfoPage se inicialice y el listener esté activo
        await Future.delayed(const Duration(milliseconds: 200));
      },
    );

    _coach!.show(context: context);
  }



  // --------- T U T O R I A L     M E T H O D S    -------------

  /// Inicia el timer de autoscroll aleatorio para los sliders
  void _startRandomAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || widget.controller.selectedIndexNotifier.value != 3) {
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

  @override
  void initState() {
    super.initState();

    loadData();

    _tabListener = () async {
      if (widget.controller.selectedIndexNotifier.value == 3) {
        await loadData();
        _tryStartExchangeTutorial();
        // Iniciar el timer de autoscroll aleatorio cuando se selecciona el tab
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _startRandomAutoScroll();
            }
          });
        });
      } else {
        // Detener el timer cuando se cambia de tab
        _autoScrollTimer?.cancel();
      }
    };
    widget.controller.selectedIndexNotifier.addListener(_tabListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.controller.selectedIndexNotifier.value == 3) {
        await loadData();
        _tryStartExchangeTutorial();
        // Iniciar el timer de autoscroll aleatorio
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _startRandomAutoScroll();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    widget.controller.selectedIndexNotifier.removeListener(_tabListener);
    _refreshTimer?.cancel();
    _autoScrollTimer?.cancel();
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
                    onPressed: _isLoadingStore ? null : () async {
                      Common().vibrate();
                      Common().applyImmersive();
                      
                      // Bloquear el botón y mostrar loading
                      setState(() {
                        _isLoadingStore = true;
                      });
                      
                      try {
                        final preloadedData = await StorePage.preloadStoreData();
                        if (!mounted) return;

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StorePage(
                              preloadedBuyOptions: preloadedData['buyOptions'] as List<Map<String, dynamic>>,
                              preloadedAdRewardOptions: preloadedData['adRewardOptions'] as List<Map<String, dynamic>>,
                              preloadedCurrency: preloadedData['currency'] as String,
                              preloadedRewardPrize: preloadedData['rewardPrize'] as int,
                            ),
                          ),
                        );
                        if (!mounted) return;
                        loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al cargar la tienda: $e')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isLoadingStore = false);
                        }
                      }
                    },
                    child: _isLoadingStore
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
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
                  style: GoogleFonts.syncopate(
                    fontSize: 24,
                    fontWeight: FontWeight.w100,
                    color: Colors.white,
                  ),
                )
              ],
            ),
            Expanded(
              key: _kWithdrawGroup,
              child: ListView.separated(
                itemCount: _exchangeOptions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 1),
                itemBuilder: (context, index) {
                  final option = _exchangeOptions[index];
                  final requiredCoins = option['coins'] as int;
                  final currencyAmount = option['euros'] as int;
                  final currentPoints = double.tryParse(_userPoints) ?? 0.0;
                  final canExchange = currentPoints >= requiredCoins;

                  // Crear o obtener la key para este slider
                  if (!_sliderKeys.containsKey(index)) {
                    _sliderKeys[index] = GlobalKey<_ExchangeSliderState>();
                  }

                  return _ExchangeSlider(
                    key: _sliderKeys[index],
                    coins: requiredCoins,
                    currencyAmount: currencyAmount,
                    currency: _currency,
                    canExchange: canExchange,
                    isLoading: _loadingSliders.contains(index),
                    onSlideComplete: () async {
                      if (!canExchange) {
                        Common().vibrate(300, 200);
                        Common().applyImmersive();
                        setState(() => _isUserPointsHighlighted = true);
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (mounted) {
                            setState(() => _isUserPointsHighlighted = false);
                          }
                        });
                        return;
                      }

                      if (!_isVerified) {
                        Common().applyImmersive();
                        showNotVerifiedDialog(context);
                        return;
                      }

                      Common().vibrate();
                      Common().applyImmersive();
                      
                      // Bloquear solo este slider específico y mostrar loading
                      if (mounted) {
                        setState(() {
                          _loadingSliders.add(index);
                        });
                      }
                      
                      try {
                        // Precargar datos de WithdrawPage antes de navegar
                        final preloadedData = await WithdrawPage.preloadWithdrawData();
                        
                        if (!mounted) return;
                        
                        // Validar que los datos precargados sean válidos
                        if (preloadedData['userId'] == null) {
                          // Si no hay userId, cargar normalmente sin precarga
                          await WidgetsBinding.instance.endOfFrame;
                          await Future.delayed(const Duration(milliseconds: 300));
                          
                          if (!mounted) return;
                          
                          // Navegar a WithdrawPage sin datos precargados
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WithdrawPage(
                                coins: requiredCoins,
                                currencyAmount: currencyAmount,
                                controller: widget.controller,
                              ),
                            ),
                          );

                          if (mounted && result == true) {
                            loadData();
                          }
                        } else {
                          // Esperar a que la página actual se renderice completamente
                          await WidgetsBinding.instance.endOfFrame;
                          await Future.delayed(const Duration(milliseconds: 300));
                          
                          if (!mounted) return;
                          
                          // Esperar a que el frame se renderice con el estado de loading
                          await Future.delayed(const Duration(milliseconds: 200));
                          await WidgetsBinding.instance.endOfFrame;
                          
                          if (!mounted) return;
                          
                          // Navegar a WithdrawPage con datos precargados
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WithdrawPage(
                                coins: requiredCoins,
                                currencyAmount: currencyAmount,
                                controller: widget.controller,
                                preloadedUserAvailableMethods: preloadedData['userAvailableMethods'] as Map<String, Map<String, String>>?,
                                preloadedCurrency: preloadedData['currency'] as String?,
                                preloadedCoinIconBase64: preloadedData['coinIconBase64'] as String?,
                                preloadedUserId: preloadedData['userId'] as String?,
                              ),
                            ),
                          );

                          if (mounted && result == true) {
                            loadData();
                          }
                        }
                      } catch (e) {
                        // Si hay un error en la precarga, navegar normalmente
                        debugPrint('Error precargando datos de WithdrawPage: $e');
                        if (!mounted) return;
                        
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WithdrawPage(
                              coins: requiredCoins,
                              currencyAmount: currencyAmount,
                              controller: widget.controller,
                            ),
                          ),
                        );

                        if (mounted && result == true) {
                          loadData();
                        }
                      } finally {
                        // Desbloquear solo este slider específico
                        if (mounted) {
                          setState(() {
                            _loadingSliders.remove(index);
                          });
                        }
                      }
                    },
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

class _ExchangeSlider extends StatefulWidget {
  final int coins;
  final int currencyAmount;
  final String currency;
  final bool canExchange;
  final bool isLoading;
  final VoidCallback onSlideComplete;

  const _ExchangeSlider({
    super.key,
    required this.coins,
    required this.currencyAmount,
    required this.currency,
    required this.canExchange,
    this.isLoading = false,
    required this.onSlideComplete,
  });

  @override
  State<_ExchangeSlider> createState() => _ExchangeSliderState();
}

class _ExchangeSliderState extends State<_ExchangeSlider> with SingleTickerProviderStateMixin {
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
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.15, end: 0.12)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 0.3,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.12, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1.0,
      ),
    ]).animate(_autoSlideController);

    _autoSlideAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _sliderValue = _autoSlideAnimation.value;
        });
      }
    });
  }

  @override
  void didUpdateWidget(_ExchangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resetear el slider cuando el loading cambia de true a false
    if (oldWidget.isLoading && !widget.isLoading && _sliderValue >= 0.95) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          resetSlider();
        }
      });
    }
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

  /// Método público para resetear el slider
  void resetSlider() {
    if (mounted) {
      setState(() {
        _sliderValue = 0.0;
        _isPressed = false;
      });
    }
  }

  @override
  void dispose() {
    _autoSlideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: Colors.transparent.withAlpha(30),
          borderRadius: BorderRadius.circular(50.0),
          boxShadow: [
            BoxShadow(
              color: (widget.canExchange ? Colors.green : Colors.red)
                  .withAlpha(60),
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
                    size: 35,
                    color: widget.canExchange ? Colors.white54 : Colors.red[300],
                  ),
                ),
              ),
            ),
            // Fondo: Contenedor de moneda (EUR/USD) - fondo fijo a la derecha
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Contenedor de moneda (derecha) - fondo fijo
                    Container(
                      width: 90,
                      height: 70,
                      margin: const EdgeInsets.only(left: 6.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.canExchange
                              ? [
                                  Colors.green[600]!,
                                  Colors.green[600]!.withAlpha(200),
                                ]
                              : [
                                  Colors.red[600]!,
                                  Colors.red[600]!.withAlpha(200),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(60.0),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.canExchange
                                    ? Colors.green
                                    : Colors.red)
                                .withAlpha(80),
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
                            widget.currency == 'eur'
                                ? 'assets/euro.png'
                                : 'assets/dollar.png',
                            width: 35,
                            height: 28,
                          ), 
                          const SizedBox(width: 1),
                          Text(
                            '${widget.currencyAmount}',
                            style: GoogleFonts.syncopate(
                              fontSize: 15,
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
            // Primer plano: Contenedor de monedas que se desliza desde la izquierda
            LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                // Ancho igual al contenedor fijo de moneda
                final containerWidth = 100.0;
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
                          height: 70,
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
                                    'assets/coin.png',
                                    width: 28,
                                    height: 28,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    NumberFormat.compact().format(widget.coins),
                                    style: GoogleFonts.syncopate(
                                      fontSize: 16,
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
                      ),
                    ),
                  ),
                );
              },
            ),
            // CircularProgressIndicator cuando está en loading
            if (widget.isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            // Slider invisible para capturar gestos
            Positioned.fill(
              child: SliderTheme(
                data: SliderThemeData(
                  trackShape: const ExchangeSliderTrackShape(),
                  thumbShape: const ExchangeSliderThumbShape(),
                  trackHeight: 0,
                  thumbColor: Colors.transparent,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  overlayShape: SliderComponentShape.noOverlay,
                  overlayColor: Colors.transparent,
                ),
                child: Slider(
                  value: _sliderValue,
                  onChanged: widget.isLoading
                      ? null
                      : widget.canExchange
                          ? (value) {
                              _autoSlideController.stop();
                              _autoSlideController.reset();
                              setState(() {
                                _sliderValue = value;
                                _isPressed = true;
                              });
                            }
                          : (value) {
                              _autoSlideController.stop();
                              _autoSlideController.reset();
                              // Limitar el deslizamiento cuando no se puede intercambiar
                              if (value > 0.2) {
                                Common().vibrate(300, 200);
                                setState(() {
                                  _sliderValue = 0.0;
                                  _isPressed = false;
                                });
                              } else {
                                setState(() {
                                  _sliderValue = value;
                                  _isPressed = true;
                                });
                              }
                            },
                  onChangeStart: widget.isLoading
                      ? null
                      : (_) {
                          _autoSlideController.stop();
                          _autoSlideController.reset();
                          setState(() => _isPressed = true);
                        },
                  onChangeEnd: widget.isLoading
                      ? null
                      : (value) {
                          setState(() => _isPressed = false);
                          if (value >= 0.9 && widget.canExchange) {
                            // Mantener el slider en 100% y llamar al callback
                            setState(() => _sliderValue = 1.0);
                            widget.onSlideComplete();
                            // El reset se hará después de que termine la navegación
                          } else {
                            setState(() => _sliderValue = 0.0);
                            // Si el usuario intentó deslizar cuando no puede intercambiar
                            if (!widget.canExchange && value > 0.3) {
                              // Mostrar feedback visual
                              widget.onSlideComplete();
                            }
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
