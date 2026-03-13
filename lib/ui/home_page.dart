import 'dart:async';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/models/favorites.dart';
import 'package:betrader/services/bets_service.dart';
import 'package:betrader/ui/betshistory_page.dart';
import 'package:betrader/ui/settings_view.dart';
import 'package:betrader/ui/store_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../helpers/common.dart';
import '../helpers/preload_cache.dart';
import '../models/bets.dart';
import '../models/trends.dart';
import 'layout_page.dart';
import 'notifications_page.dart';

/// The main home screen widget displaying trends, favorites, and recent bets.
///
/// This screen serves as the primary dashboard showing trending assets,
/// user favorites, and active bets. It includes auto-scrolling trends and
/// periodic data refresh functionality.
class HomeScreen extends StatefulWidget {
  /// Controller for managing the main menu navigation.
  final MainMenuPageController controller;
  /// Llamado cuando el tutorial del home se omite o termina (para mostrar recompensa diaria después).
  final VoidCallback? onHomeTutorialFinished;
  const HomeScreen({
    super.key,
    required this.controller,
    this.onHomeTutorialFinished,
  });

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const String _startTutorialFlag = 'START_TUTORIAL';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Future<BetsAndPriceBets>? _investmentFuture;
  bool _investInited = false;
  List<Bet> _bets = [];
  List<PriceBet> _priceBets = [];
  String? _userId;
  double _userPoints = 0;
  late Future<Trends> _trendsFuture;
  late Future<Favorites> _favsFuture;
  Trends? _currentTrends; // Mantener datos actuales para evitar skeletons
  Favorites? _currentFavorites; // Mantener datos actuales para evitar skeletons
  bool _userIsInteracting = false;
  bool _userIsInteractingFavs = false;
  bool _favsInitialPositionSet = false;
  bool _isLoadingStore = false;
  final ScrollController _trendScrollController = ScrollController();
  final ScrollController _favsScrollController = ScrollController();
  Ticker? _ticker;
  Ticker? _favsTicker;
  double _direction = 1;
  double _favsDirection = -1; // Comienza moviéndose hacia la izquierda
  Timer? _refreshTimer;
  double _lastTrendScrollOffset = 0.0;
  double _lastFavsScrollOffset = 0.0;
  final GlobalKey _kSettings = GlobalKey();
  final GlobalKey _kStore = GlobalKey();
  final GlobalKey _kTrends = GlobalKey();
  final GlobalKey _kFavorites = GlobalKey();
  final GlobalKey _kBets = GlobalKey();
  final GlobalKey _kHistory = GlobalKey();
  TutorialCoachMark? _coach;
  bool _dollarCurrency = false;
  bool _isRefreshing = false; // Flag para evitar múltiples refreshes simultáneos

  /// Re-reads user points from storage and updates the UI.
  /// Call after points have been updated server-side (e.g. after claiming daily reward).
  void refreshUserPoints() async {
    final p = await _storage.read(key: 'points') ?? '0';
    if (mounted) {
      setState(() {
        _userPoints = double.tryParse(p) ?? 0;
      });
    }
  }

  /// Refreshes user data, trends, and favorites without reloading investments.
  ///
  /// Updates user points, currency preference, and fetches latest trends
  /// and favorites data from the server. Mantiene los datos actuales mientras
  /// se cargan los nuevos para evitar skeletons.
  void _refreshData() async {
    // Evitar múltiples refreshes simultáneos
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final userId = await _storage.read(key: "sessionToken") ?? "none";
      await BetsService().getUserInfo(userId);
      final userPoints = await _storage.read(key: "points") ?? "0";
      final prefs = await SharedPreferences.getInstance();
      final dollarCurrency = prefs.getBool('dollarCurrency') ?? false;

      if (!mounted) {
        _isRefreshing = false;
        return;
      }

      // Actualizar datos del usuario primero (solo si cambió)
      if (_userId != (userId != "none" ? userId : null) ||
          _userPoints != (double.tryParse(userPoints) ?? 0) ||
          _dollarCurrency != dollarCurrency) {
        setState(() {
          _userId = userId != "none" ? userId : null;
          _userPoints = double.tryParse(userPoints) ?? 0;
          _dollarCurrency = dollarCurrency;
        });
      }

      // Cargar nuevos datos en segundo plano sin cambiar los Futures inmediatamente
      // Esto evita que los FutureBuilder vuelvan a estado 'waiting'
      final newTrendsFuture = BetsService()
          .fetchTrendsData(_userId ?? "none", _dollarCurrency ? 'USD' : 'EUR');
      final newFavsFuture = BetsService()
          .fetchFavouritesData(_userId ?? "none", _dollarCurrency ? 'USD' : 'EUR');

      // Esperar a que los datos estén listos antes de actualizar
      try {
        final newTrends = await newTrendsFuture;
        if (!mounted) {
          _isRefreshing = false;
          return;
        }
        // Solo actualizar si los datos realmente cambiaron
        if (_currentTrends == null || !_areTrendsEqual(_currentTrends!, newTrends)) {
          setState(() {
            _currentTrends = newTrends;
            // Actualizar el Future solo si hay datos previos para evitar parpadeos
            _trendsFuture = Future.value(newTrends);
          });
        }
      } catch (e) {
        // Si hay error, mantener los datos anteriores
        if (kDebugMode) {
          print('Error refreshing trends: $e');
        }
      }

      try {
        final newFavs = await newFavsFuture;
        if (!mounted) {
          _isRefreshing = false;
          return;
        }
        // Solo actualizar si los datos realmente cambiaron
        if (_currentFavorites == null || !_areFavoritesEqual(_currentFavorites!, newFavs)) {
          setState(() {
            _currentFavorites = newFavs;
            // Actualizar el Future solo si hay datos previos para evitar parpadeos
            _favsFuture = Future.value(newFavs);
            // Reset el flag para que se posicione al final de nuevo cuando se refresque
            _favsInitialPositionSet = false;
          });
        }
      } catch (e) {
        // Si hay error, mantener los datos anteriores
        if (kDebugMode) {
          print('Error refreshing favorites: $e');
        }
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// Compara si dos objetos Trends son iguales (comparación simple por IDs)
  bool _areTrendsEqual(Trends a, Trends b) {
    if (a.trends.length != b.trends.length) return false;
    final aIds = a.trends.map((t) => t.id).toSet();
    final bIds = b.trends.map((t) => t.id).toSet();
    return aIds.length == bIds.length && aIds.every((id) => bIds.contains(id));
  }

  /// Compara si dos objetos Favorites son iguales (comparación simple por tickers)
  bool _areFavoritesEqual(Favorites a, Favorites b) {
    if (a.favorites.length != b.favorites.length) return false;
    final aTickers = a.favorites.map((f) => f.ticker).toSet();
    final bTickers = b.favorites.map((f) => f.ticker).toSet();
    return aTickers.length == bTickers.length && aTickers.every((t) => bTickers.contains(t));
  }

  /// Loads user ID and initializes all data including investments.
  ///
  /// Usa datos precargados durante "Cargando..." si existen; si no, fetchea
  /// trends, favorites e investment data.
  Future<void> loadUserIdAndData() async {
    final userId = await _storage.read(key: "sessionToken") ?? "none";
    final userPoints = await _storage.read(key: "points") ?? "0";
    final prefs = await SharedPreferences.getInstance();
    final dollarCurrency = prefs.getBool('dollarCurrency') ?? false;

    if (!mounted) return;

    // Usar datos precargados durante "Cargando..." si existen
    final (cachedTrends, cachedFavs, cachedInvest) = PreloadCache.takeHomeData();
    if (cachedTrends != null && cachedFavs != null && cachedInvest != null && mounted) {
      if (kDebugMode) {
        print('[HomeScreen] using cached home data: trends=${cachedTrends.trends.length}');
      }
      setState(() {
        _userId = userId != "none" ? userId : null;
        _userPoints = double.tryParse(userPoints) ?? 0;
        _dollarCurrency = dollarCurrency;
        _trendsFuture = Future.value(cachedTrends);
        _favsFuture = Future.value(cachedFavs);
        _investmentFuture = Future.value(cachedInvest);
        _currentTrends = cachedTrends;
        _currentFavorites = cachedFavs;
        _bets = List.from(cachedInvest.bets.investList);
        _priceBets = List.from(cachedInvest.priceBets);
        _investInited = true;
      });
      return;
    }

    setState(() {
      _userId = userId != "none" ? userId : null;
      _userPoints = double.tryParse(userPoints) ?? 0;
      _dollarCurrency = dollarCurrency;
      _trendsFuture = BetsService()
          .fetchTrendsData(_userId ?? "none", _dollarCurrency ? 'USD' : 'EUR');
      _favsFuture = BetsService()
          .fetchFavouritesData(_userId ?? "none", _dollarCurrency ? 'USD' : 'EUR');
      _investmentFuture = BetsService()
          .fetchInvestmentData(_userId ?? "none", _dollarCurrency ? 'USD' : 'EUR');
    });
    if (kDebugMode) {
      print('[HomeScreen] trends future started (userId=${_userId ?? "none"}, currency=${_dollarCurrency ? "USD" : "EUR"})');
    }

    _trendsFuture.then((trends) {
      if (!mounted) return;
      if (kDebugMode) {
        print('[HomeScreen] trends future completed: ${trends.trends.length} trends');
      }
      setState(() {
        _currentTrends = trends;
      });
    }).catchError((e, st) {
      if (kDebugMode) {
        print('[HomeScreen] trends future ERROR: $e');
        print('[HomeScreen] stack: $st');
      }
    });

    _favsFuture.then((favs) {
      if (!mounted) return;
      setState(() {
        _currentFavorites = favs;
      });
    }).catchError((_) {});

    final future = _investmentFuture;
    if (future != null) {
      future.then((data) {
        if (!mounted) return;
        setState(() {
          _bets = List.from(data.bets.investList);
          _priceBets = List.from(data.priceBets);
          _investInited = true;
        });
      });
    }
  }

  /// Refreshes the favorites list by fetching updated data from the server.
  void refreshFavorites() {
    // Cargar nuevos datos en segundo plano sin cambiar el Future inmediatamente
    final newFavsFuture = BetsService()
        .fetchFavouritesData(_userId ?? "none", _dollarCurrency ? 'USD' : 'EUR');
    
    newFavsFuture.then((newFavs) {
      if (!mounted) return;
      setState(() {
        _currentFavorites = newFavs;
        _favsFuture = Future.value(newFavs);
        // Reset el flag para que se posicione al final de nuevo cuando se refresque
        _favsInitialPositionSet = false;
      });
    }).catchError((_) {
      // Si hay error, mantener los datos anteriores
    });
  }

  /// Refreshes the investments list (bets and price bets) from the server.
  ///
  /// Updates the displayed bets without requiring a full page reload.
  Future<void> refreshInvestments() async {
    if (!mounted || _userId == null) return;
    try {
      final data = await BetsService()
          .fetchInvestmentData(_userId!, _dollarCurrency ? 'USD' : 'EUR');
      if (!mounted) return;
      setState(() {
        _bets = List.from(data.bets.investList);
        _priceBets = List.from(data.priceBets);
      });
    } catch (_) {}
  }

  /// Initializes auto-scroll functionality after a delay.
  ///
  /// Waits 3 seconds before starting automatic scrolling of trends to
  /// allow initial rendering to complete.
  void _delayedAutoScrollInit() async {
    await Future.delayed(const Duration(seconds: 3));
    _startAutoScroll();
  }

  /// Starts automatic scrolling of the trends list.
  ///
  /// Scrolls back and forth automatically when user is not interacting.
  /// Pauses scrolling when user touches the screen.
  void _startAutoScroll() {
    // Inicializar la última posición
    if (_trendScrollController.hasClients) {
      _lastTrendScrollOffset = _trendScrollController.offset;
    }
    
    _ticker = Ticker((Duration elapsed) {
      if (!_trendScrollController.hasClients) return;
      if (_userIsInteracting) return;

      final max = _trendScrollController.position.maxScrollExtent;
      final min = 0.0;
      double offset = _trendScrollController.offset + _direction * 0.5;

      if (offset >= max) {
        _direction = -1;
        offset = max;
      } else if (offset <= min) {
        _direction = 1;
        offset = min;
      }

      _trendScrollController.jumpTo(offset);
      _lastTrendScrollOffset = offset;
    });

    _ticker!.start();
  }

  /// Starts automatic scrolling of the favorites list.
  ///
  /// Scrolls back and forth automatically when user is not interacting.
  /// Pauses scrolling when user touches the screen.
  /// Starts from the right (end) and moves first to the left.
  void _startFavsAutoScroll() async {
    // Esperar a que el ScrollController esté listo
    for (int i = 0; i < 50; i++) {
      if (!mounted) return;
      if (_favsScrollController.hasClients) {
        try {
          final max = _favsScrollController.position.maxScrollExtent;
          if (max > 0) {
            // Asegurar que está posicionado al final (derecha) y la dirección sea hacia la izquierda
            final currentOffset = _favsScrollController.offset;
            if ((max - currentOffset).abs() > 1.0) {
              // Solo reposicionar si no está cerca del final (por si acaso)
              _favsScrollController.jumpTo(max);
            }
            _favsDirection = -1; // Asegurar dirección hacia la izquierda
            _lastFavsScrollOffset = _favsScrollController.offset;
            break;
          }
        } catch (e) {
          // Ignorar errores de inicialización
        }
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) return;

    // Inicializar la última posición si no se hizo antes
    if (_favsScrollController.hasClients) {
      _lastFavsScrollOffset = _favsScrollController.offset;
    }

    // Ahora iniciar el ticker que se moverá hacia la izquierda
    _favsTicker = Ticker((Duration elapsed) {
      if (!mounted) return;
      if (!_favsScrollController.hasClients) return;
      if (_userIsInteractingFavs) return;

      try {
        final max = _favsScrollController.position.maxScrollExtent;
        // Si no hay scroll disponible (maxScrollExtent <= 0), no hacer nada
        if (max <= 0) return;

        final min = 0.0;
        double offset = _favsScrollController.offset + _favsDirection * 0.5;

        if (offset >= max) {
          _favsDirection = -1; // Cambiar a izquierda cuando llega al final
          offset = max;
        } else if (offset <= min) {
          _favsDirection = 1; // Cambiar a derecha cuando llega al inicio
          offset = min;
        }

        _favsScrollController.jumpTo(offset);
        _lastFavsScrollOffset = offset;
      } catch (e) {
        // Si hay algún error con el ScrollController, detener el ticker
        _favsTicker?.stop();
      }
    });

    _favsTicker!.start();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _delayedAutoScrollInit();
      // Iniciar auto-scroll de favoritos después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        _startFavsAutoScroll();
      });

      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool(_startTutorialFlag) ?? false;
      if (!alreadyShown) {
        await prefs.setBool(_startTutorialFlag, true);

        if (mounted) {
          startHomeTutorial();
        }
      }
    });

    loadUserIdAndData();

    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      _refreshData();
      await refreshInvestments();
      // Actualizar max odds de la vista Markets (etiquetas por activo) sin bloquear
      marketsPageKey.currentState?.refreshMaxOdds();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Cuando la app vuelve a primer plano, refrescar los datos en segundo plano
      // sin forzar actualizaciones inmediatas que causan parpadeos
      if (mounted && !_isRefreshing) {
        // Refrescar los datos en segundo plano
        // El método _refreshData ya maneja la actualización inteligente de Futures
        _refreshData();
        refreshInvestments();
        marketsPageKey.currentState?.refreshMaxOdds();
      }
    }
  }

  /// Checks if a tutorial has been seen by the user.
  ///
  /// [key] The tutorial identifier key.
  /// Returns `true` if the tutorial has been marked as seen.
  Future<bool> _hasSeen(String key) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('__tutorial_seen__$key') ?? false;
  }

  /// Marks a tutorial as seen by the user.
  ///
  /// [key] The tutorial identifier key to mark as seen.
  Future<void> _markSeen(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('__tutorial_seen__$key', true);
  }

  /// Builds the list of tutorial targets for the home screen onboarding.
  ///
  /// Creates target focus points for settings, store, trends, favorites,
  /// bets, and history sections with localized descriptions.
  ///
  /// Returns a list of [TargetFocus] objects for the tutorial coach mark.
  List<TargetFocus> _buildTargets() {
    final LocalizedStrings? strings = LocalizedStrings.of(context);
    return [
      TargetFocus(
        identify: 'settings',
        keyTarget: _kSettings,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (ctx, ctrl) => Common().bubble(
              strings!.get('settings') ?? 'Settings',
              strings.get('tutorial_settings_body') ??
                  'Manage your account, notifications, security, and app preferences. Open it later to fine-tune details without leaving the tour.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'store',
        keyTarget: _kStore,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (ctx, ctrl) => Common().bubble(
              strings!.get('tutorial_store_title') ?? 'Store',
              strings.get('tutorial_store_body') ??
                  'Check your coin balance, redeem rewards, and browse offers. We’ll open it afterwards so you don’t miss the rest of the tour.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'trends',
        keyTarget: _kTrends,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (ctx, ctrl) => Common().bubble(
              strings!.get('trends') ?? 'Trends',
              strings.get('tutorial_trends_body') ??
                  'Your first trending asset shows up here with live movement and key stats. Tap to open the detail view and learn how to place a bet on it.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'favorites',
        keyTarget: _kFavorites,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (ctx, ctrl) => Common().bubble(
              strings!.get('favs') ?? 'Favorites',
              strings.get('tutorial_favorites_body') ??
                  'Pinned assets you follow closely. Add or remove favorites to keep this section clean and quick to access.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'bets',
        keyTarget: _kBets,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (ctx, ctrl) => Common().bubble(
              strings!.get('tutorial_bets_title') ?? 'Recent bets',
              strings.get('tutorial_bets_body') ??
                  'A quick snapshot of your most recent bets, updated in real time. Use it to review outcomes or jump back into an asset.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'history',
        keyTarget: _kHistory,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (ctx, ctrl) => Common().bubble(
              strings!.get('tutorial_history_title') ?? 'Bet history',
              strings.get('tutorial_history_body') ??
                  'A complete log of past bets with results and timestamps. Open it to filter, inspect details, and learn from previous moves.',
            ),
          ),
        ],
      )
    ];
  }

  /// Starts the home screen tutorial/onboarding flow.
  ///
  /// Waits for all UI elements to be ready, then displays a tutorial
  /// coach mark guiding users through the main features. Only shows
  /// if the tutorial hasn't been seen before.
  Future<void> startHomeTutorial() async {
    LocalizedStrings? strings = LocalizedStrings.of(context);
    if (!mounted) return;

    if (await _hasSeen('home_onboarding_v1')) return;

    for (int i = 0; i < 25; i++) {
      if (!mounted) return;
      final trendReady = _kTrends.currentContext != null || _userId == null;
      final settingsReady = _kSettings.currentContext != null;
      final storeReady = _kStore.currentContext != null;
      final favsReady = _kFavorites.currentContext != null;
      final betsReady = _kBets.currentContext != null;
      final historyReady = _kHistory.currentContext != null;
      if (trendReady && settingsReady && storeReady && favsReady && betsReady && historyReady) break;
      await Future.delayed(const Duration(milliseconds: 80));
    }

    final targets =
    _buildTargets().where((t) => t.keyTarget?.currentContext != null).toList();
    if (targets.isEmpty) return;

    _coach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      textSkip: strings!.get('tutorial_skip') ?? 'Skip tutorial',
      textStyleSkip: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
      hideSkip: false,
      useSafeArea: true,
      pulseEnable: true,
      alignSkip: Alignment.bottomRight,
      initialFocus: 0,
      disableBackButton: true,
      onClickTarget: (target) async {},
      onClickOverlay: (target) {},
      onSkip: () {
        Common().markAllTutorialsSeen();
        widget.onHomeTutorialFinished?.call();
        return true;
      },
      onFinish: () async {
        await _markSeen('home_onboarding_v1');
        final p = await SharedPreferences.getInstance();
        await p.setBool('__tutorial_pending__awards_v1', true);

        // No llamar onHomeTutorialFinished aquí: el flujo continúa en Awards.
        // La recompensa diaria se mostrará al omitir o al terminar el último tutorial (UserInfo).

        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          widget.controller.updateIndex(1);
        });
      },
    );

    _coach!.show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                IconButton(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                  icon: Icon(key: _kSettings, Icons.settings),
                  iconSize: 25,
                  color: Colors.white70,
                  onPressed: () {
                    Common().vibrate();
                    Common().applyImmersive();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsView(
                          onPersonalInfoTap: () {
                            Common().applyImmersive();
                            Navigator.pop(context);
                            widget.controller.updateIndex(4);
                          },
                          onShowNotifications: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotificationsPage(
                                  onBack: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            );
                          },
                          controller: widget.controller,
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(flex: 5),
                Text(
                  "betrader.v1",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syncopate(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const Spacer(flex: 4),
                IconButton(
                  key: _kStore,
                  padding: const EdgeInsets.all(2.5),
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
                      exchangePageKey.currentState?.loadData();
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
                  icon: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.grey.shade800.withValues(alpha: 1.0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: _isLoadingStore
                          ? SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 2),
                                  child: Image.asset(
                                    'assets/coin.png',
                                    width: 25,
                                    height: 25,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  NumberFormat.compact().format(_userPoints),
                                  style: GoogleFonts.montserrat(color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              flex: 9,
              child: Container(
                key: _kTrends,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings?.get('trends') ?? 'Trends',
                      style: GoogleFonts.syncopate(
                          fontSize: 18, fontWeight: FontWeight.w200),
                    ),
                    const Divider(color: Colors.white, thickness: 0.5, height: 0.5),
                    Expanded(
                      child: _userId == null
                          ? Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: const [
                              SizedBox(width: 8),
                              SkeletonTrendContainer(),
                              SizedBox(width: 8),
                              SkeletonTrendContainer(),
                              SizedBox(width: 8),
                              SkeletonTrendContainer(),
                              SizedBox(width: 8),
                            ],
                          ),
                        ),
                      )
                          : FutureBuilder<Trends>(
                        future: _trendsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.none) {
                            if (kDebugMode){
                              print('[HomeScreen] FutureBuilder trends: state=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}, dataLength=${snapshot.data?.trends.length ?? 0}, _currentTrends=${_currentTrends?.trends.length ?? 0}');
                            }
                          }
                          // Si está cargando pero tenemos datos previos, mostrar esos datos
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            if (_currentTrends != null && _currentTrends!.trends.isNotEmpty) {
                              final data = _currentTrends!;
                              return NotificationListener<ScrollNotification>(
                                onNotification: (ScrollNotification notification) {
                                  if (notification is ScrollUpdateNotification) {
                                    final currentOffset = notification.metrics.pixels;
                                    if (currentOffset > _lastTrendScrollOffset) {
                                      _direction = 1;
                                    } else if (currentOffset < _lastTrendScrollOffset) {
                                      _direction = -1;
                                    }
                                    _lastTrendScrollOffset = currentOffset;
                                  } else if (notification is ScrollEndNotification) {
                                  }
                                  return false;
                                },
                                child: Listener(
                                  onPointerDown: (_) {
                                    _userIsInteracting = true;
                                    Common().applyImmersive();
                                  },
                                  onPointerUp: (_) async {
                                    await Future.delayed(
                                        const Duration(milliseconds: 100));
                                    _userIsInteracting = false;
                                  },
                                  child: ListView.builder(
                                    controller: _trendScrollController,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: data.trends.length,
                                    itemBuilder: (context, index) {
                                      final sortedTrends =
                                      List.from(data.trends)
                                        ..sort((a, b) =>
                                            a.id.compareTo(b.id));
                                      final sortedIndex =
                                          sortedTrends[index].id - 1;

                                      return TrendContainer(
                                        trend: sortedTrends[index],
                                        index: sortedIndex,
                                        onFavoriteUpdated: refreshFavorites,
                                        controller: widget.controller,
                                      );
                                    },
                                  ),
                                ),
                              );
                            }
                            // Solo mostrar skeleton si no hay datos previos
                            return Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: const [
                                    SizedBox(width: 8),
                                    SkeletonTrendContainer(),
                                    SizedBox(width: 8),
                                    SkeletonTrendContainer(),
                                    SizedBox(width: 8),
                                    SkeletonTrendContainer(),
                                    SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            // Si hay error pero tenemos datos previos, mostrar esos datos
                            if (_currentTrends != null && _currentTrends!.trends.isNotEmpty) {
                              final data = _currentTrends!;
                              return NotificationListener<ScrollNotification>(
                                onNotification: (ScrollNotification notification) {
                                  if (notification is ScrollUpdateNotification) {
                                    final currentOffset = notification.metrics.pixels;
                                    if (currentOffset > _lastTrendScrollOffset) {
                                      _direction = 1;
                                    } else if (currentOffset < _lastTrendScrollOffset) {
                                      _direction = -1;
                                    }
                                    _lastTrendScrollOffset = currentOffset;
                                  } else if (notification is ScrollEndNotification) {
                                  }
                                  return false;
                                },
                                child: Listener(
                                  onPointerDown: (_) {
                                    _userIsInteracting = true;
                                    Common().applyImmersive();
                                  },
                                  onPointerUp: (_) async {
                                    await Future.delayed(
                                        const Duration(milliseconds: 100));
                                    _userIsInteracting = false;
                                  },
                                  child: ListView.builder(
                                    controller: _trendScrollController,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: data.trends.length,
                                    itemBuilder: (context, index) {
                                      final sortedTrends =
                                      List.from(data.trends)
                                        ..sort((a, b) =>
                                            a.id.compareTo(b.id));
                                      final sortedIndex =
                                          sortedTrends[index].id - 1;

                                      return TrendContainer(
                                        trend: sortedTrends[index],
                                        index: sortedIndex,
                                        onFavoriteUpdated: refreshFavorites,
                                        controller: widget.controller,
                                      );
                                    },
                                  ),
                                ),
                              );
                            }
                            return Text('Error: ${snapshot.error}');
                          } else if (snapshot.hasData &&
                              snapshot.data!.trends.isNotEmpty) {
                            final data = snapshot.data!;
                            if (kDebugMode) {
                              print('[HomeScreen] FutureBuilder showing ${data.trends.length} trends from snapshot');
                            }
                            // Actualizar datos actuales cuando se reciben nuevos
                            if (_currentTrends != data) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _currentTrends = data;
                                  });
                                }
                              });
                            }
                            return NotificationListener<ScrollNotification>(
                              onNotification: (ScrollNotification notification) {
                                if (notification is ScrollUpdateNotification) {
                                  // Rastrear la dirección del scroll
                                  final currentOffset = notification.metrics.pixels;
                                  if (currentOffset > _lastTrendScrollOffset) {
                                    // Scrolling hacia la derecha
                                    _direction = 1;
                                  } else if (currentOffset < _lastTrendScrollOffset) {
                                    // Scrolling hacia la izquierda
                                    _direction = -1;
                                  }
                                  _lastTrendScrollOffset = currentOffset;
                                } else if (notification is ScrollEndNotification) {
                                  // Cuando termina el fling, la dirección ya está actualizada
                                  // El auto-scroll continuará en esa dirección
                                }
                                return false;
                              },
                              child: Listener(
                                onPointerDown: (_) {
                                  _userIsInteracting = true;
                                  Common().applyImmersive();
                                },
                                onPointerUp: (_) async {
                                  await Future.delayed(
                                      const Duration(milliseconds: 100));
                                  _userIsInteracting = false;
                                },
                                child: ListView.builder(
                                  controller: _trendScrollController,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: data.trends.length,
                                  itemBuilder: (context, index) {
                                    final sortedTrends =
                                    List.from(data.trends)
                                      ..sort((a, b) =>
                                          a.id.compareTo(b.id));
                                    final sortedIndex =
                                        sortedTrends[index].id - 1;

                                    return TrendContainer(
                                      trend: sortedTrends[index],
                                      index: sortedIndex,
                                      onFavoriteUpdated: refreshFavorites,
                                      controller: widget.controller,
                                    );
                                  },
                                ),
                              ),
                            );
                          } else if (snapshot.hasData && snapshot.data!.trends.isEmpty) {
                            // API devolvió 200/404 con lista vacía: no hay trends aún (p. ej. backend no ha corrido UpdateTrends)
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  strings?.get('noTrendsYet') ?? 'No trends yet',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.white54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          } else {
                            if (kDebugMode) {
                              print('[HomeScreen] FutureBuilder trends: showing skeleton (hasData=${snapshot.hasData}, empty=${snapshot.data?.trends.isEmpty ?? true})');
                            }
                            return Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: const [
                                    SizedBox(width: 8),
                                    SkeletonTrendContainer(),
                                    SizedBox(width: 8),
                                    SkeletonTrendContainer(),
                                    SizedBox(width: 8),
                                    SkeletonTrendContainer(),
                                    SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 8,
              child: Container(
                key: _kFavorites,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          strings?.get('favs') ?? 'Favs',
                          style: GoogleFonts.syncopate(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white, thickness: 0.5, height: 0.5),
                    Expanded(
                      flex: 8,
                      child: _userId == null
                          ? Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: const [
                              SizedBox(width: 8),
                              SkeletonTrendContainer(),
                              SizedBox(width: 8),
                              SkeletonTrendContainer(),
                              SizedBox(width: 8),
                              SkeletonTrendContainer(),
                              SizedBox(width: 8),
                            ],
                          ),
                        ),
                      )
                          : FutureBuilder<Favorites>(
                        future: _favsFuture,
                        builder: (context, snapshot) {
                          // Si está cargando pero tenemos datos previos, mostrar esos datos
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            if (_currentFavorites != null && _currentFavorites!.favorites.isNotEmpty) {
                              final data = _currentFavorites!;
                              // Posicionar al final inmediatamente después del primer frame (solo una vez)
                              if (!_favsInitialPositionSet) {
                                WidgetsBinding.instance.addPostFrameCallback((_) async {
                                  for (int i = 0; i < 20; i++) {
                                    if (!mounted || _favsInitialPositionSet) return;
                                    if (_favsScrollController.hasClients) {
                                      try {
                                        final max = _favsScrollController.position.maxScrollExtent;
                                        if (max > 0) {
                                          _favsScrollController.jumpTo(max);
                                          _lastFavsScrollOffset = max;
                                          _favsDirection = -1;
                                          _favsInitialPositionSet = true;
                                          return;
                                        }
                                      } catch (e) {
                                        if (kDebugMode) {
                                          print("[ERR] Home-Error:1007");
                                        }
                                      }
                                    }
                                    await Future.delayed(const Duration(milliseconds: 16));
                                  }
                                });
                              }
                              return NotificationListener<ScrollNotification>(
                                onNotification: (ScrollNotification notification) {
                                  if (notification is ScrollUpdateNotification) {
                                    final currentOffset = notification.metrics.pixels;
                                    if (currentOffset > _lastFavsScrollOffset) {
                                      _favsDirection = 1;
                                    } else if (currentOffset < _lastFavsScrollOffset) {
                                      _favsDirection = -1;
                                    }
                                    _lastFavsScrollOffset = currentOffset;
                                  } else if (notification is ScrollEndNotification) {
                                  }
                                  return false;
                                },
                                child: Listener(
                                  onPointerDown: (_) {
                                    _userIsInteractingFavs = true;
                                    Common().applyImmersive();
                                  },
                                  onPointerUp: (_) async {
                                    await Future.delayed(
                                        const Duration(milliseconds: 100));
                                    _userIsInteractingFavs = false;
                                  },
                                  child: ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(context)
                                        .copyWith(overscroll: false),
                                    child: ListView.builder(
                                      controller: _favsScrollController,
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(
                                        decelerationRate:
                                        ScrollDecelerationRate.fast,
                                      ),
                                      itemCount: data.length,
                                      itemBuilder: (context, index) {
                                        return FavoriteContainer(
                                          favorite: data.favorites[index],
                                          onFavoriteUpdated: refreshFavorites,
                                          controller: widget.controller,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }
                            // Solo mostrar skeleton si no hay datos previos
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        children: const [
                                          SkeletonFavoriteContainer(),
                                          SkeletonFavoriteContainer(),
                                          SkeletonFavoriteContainer(),
                                          SkeletonFavoriteContainer(),
                                          SkeletonFavoriteContainer(),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          } else if (snapshot.hasError) {
                            // Si hay error pero tenemos datos previos, mostrar esos datos
                            if (_currentFavorites != null && _currentFavorites!.favorites.isNotEmpty) {
                              final data = _currentFavorites!;
                              if (!_favsInitialPositionSet) {
                                WidgetsBinding.instance.addPostFrameCallback((_) async {
                                  for (int i = 0; i < 20; i++) {
                                    if (!mounted || _favsInitialPositionSet) return;
                                    if (_favsScrollController.hasClients) {
                                      try {
                                        final max = _favsScrollController.position.maxScrollExtent;
                                        if (max > 0) {
                                          _favsScrollController.jumpTo(max);
                                          _lastFavsScrollOffset = max;
                                          _favsDirection = -1;
                                          _favsInitialPositionSet = true;
                                          return;
                                        }
                                      } catch (e) {
                                        if (kDebugMode) {
                                          print("[ERR] Home-Error:1109");
                                        }
                                      }
                                    }
                                    await Future.delayed(const Duration(milliseconds: 16));
                                  }
                                });
                              }
                              return NotificationListener<ScrollNotification>(
                                onNotification: (ScrollNotification notification) {
                                  if (notification is ScrollUpdateNotification) {
                                    final currentOffset = notification.metrics.pixels;
                                    if (currentOffset > _lastFavsScrollOffset) {
                                      _favsDirection = 1;
                                    } else if (currentOffset < _lastFavsScrollOffset) {
                                      _favsDirection = -1;
                                    }
                                    _lastFavsScrollOffset = currentOffset;
                                  } else if (notification is ScrollEndNotification) {
                                  }
                                  return false;
                                },
                                child: Listener(
                                  onPointerDown: (_) {
                                    _userIsInteractingFavs = true;
                                    Common().applyImmersive();
                                  },
                                  onPointerUp: (_) async {
                                    await Future.delayed(
                                        const Duration(milliseconds: 100));
                                    _userIsInteractingFavs = false;
                                  },
                                  child: ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(context)
                                        .copyWith(overscroll: false),
                                    child: ListView.builder(
                                      controller: _favsScrollController,
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(
                                        decelerationRate:
                                        ScrollDecelerationRate.fast,
                                      ),
                                      itemCount: data.length,
                                      itemBuilder: (context, index) {
                                        return FavoriteContainer(
                                          favorite: data.favorites[index],
                                          onFavoriteUpdated: refreshFavorites,
                                          controller: widget.controller,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Text('Error: ${snapshot.error}');
                          } else if (snapshot.hasData &&
                              snapshot.data!.favorites.isNotEmpty) {
                            final data = snapshot.data!;
                            // Actualizar datos actuales cuando se reciben nuevos
                            if (_currentFavorites != data) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _currentFavorites = data;
                                  });
                                }
                              });
                            }
                            // Posicionar al final inmediatamente después del primer frame (solo una vez)
                            if (!_favsInitialPositionSet) {
                              WidgetsBinding.instance.addPostFrameCallback((_) async {
                                // Intentar múltiples veces hasta que el ScrollController esté listo
                                for (int i = 0; i < 20; i++) {
                                  if (!mounted || _favsInitialPositionSet) return;
                                  if (_favsScrollController.hasClients) {
                                    try {
                                      final max = _favsScrollController.position.maxScrollExtent;
                                      if (max > 0) {
                                        _favsScrollController.jumpTo(max);
                                        _lastFavsScrollOffset = max;
                                        _favsDirection = -1; // Dirección hacia la izquierda
                                        _favsInitialPositionSet = true;
                                        return;
                                      }
                                    } catch (e) {
                                      // Ignorar errores de inicialización
                                    }
                                  }
                                  await Future.delayed(const Duration(milliseconds: 16)); // ~1 frame
                                }
                              });
                            }
                            return NotificationListener<ScrollNotification>(
                              onNotification: (ScrollNotification notification) {
                                if (notification is ScrollUpdateNotification) {
                                  // Rastrear la dirección del scroll
                                  final currentOffset = notification.metrics.pixels;
                                  if (currentOffset > _lastFavsScrollOffset) {
                                    // Scrolling hacia la derecha
                                    _favsDirection = 1;
                                  } else if (currentOffset < _lastFavsScrollOffset) {
                                    // Scrolling hacia la izquierda
                                    _favsDirection = -1;
                                  }
                                  _lastFavsScrollOffset = currentOffset;
                                } else if (notification is ScrollEndNotification) {
                                  // Cuando termina el fling, la dirección ya está actualizada
                                  // El auto-scroll continuará en esa dirección
                                }
                                return false;
                              },
                              child: Listener(
                                onPointerDown: (_) {
                                  _userIsInteractingFavs = true;
                                  Common().applyImmersive();
                                },
                                onPointerUp: (_) async {
                                  await Future.delayed(
                                      const Duration(milliseconds: 100));
                                  _userIsInteractingFavs = false;
                                },
                                child: ScrollConfiguration(
                                  behavior: ScrollConfiguration.of(context)
                                      .copyWith(overscroll: false),
                                  child: ListView.builder(
                                    controller: _favsScrollController,
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(
                                      decelerationRate:
                                      ScrollDecelerationRate.fast,
                                    ),
                                    itemCount: data.length,
                                    itemBuilder: (context, index) {
                                      return FavoriteContainer(
                                        favorite: data.favorites[index],
                                        onFavoriteUpdated: refreshFavorites,
                                        controller: widget.controller,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      strings!.get('noFavsYet') ??
                                          "No favorites yet!",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.syncopate(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w200,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Icon(
                                      FontAwesomeIcons.star,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 12,
              child: Container(
                key: _kBets,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          strings?.get('recentBets') ?? 'Recent Bets',
                          style: GoogleFonts.syncopate(
                              fontSize: 16, fontWeight: FontWeight.w200),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white, thickness: 0.5, height: 0.5),
                    Expanded(
                      flex: 12,
                      child: _userId == null
                          ? ListView(
                        children: const [
                          SkeletonRecentBetContainer(),
                          SkeletonRecentBetContainer(),
                        ],
                      )
                          : FutureBuilder<BetsAndPriceBets>(
                        future: _investmentFuture,
                        builder: (context, snapshot) {
                          // Si ya tenemos datos inicializados, no mostrar skeleton
                          // incluso si el Future está en estado waiting
                          if (!_investInited &&
                              snapshot.connectionState ==
                                  ConnectionState.waiting) {
                            return ListView(
                              children: const [
                                SkeletonRecentBetContainer(),
                                SkeletonRecentBetContainer(),
                              ],
                            );
                          }

                          if (!_investInited && snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          // Si el Future está en estado waiting pero ya tenemos datos,
                          // mostrar los datos actuales en lugar de skeleton
                          if (snapshot.connectionState == ConnectionState.waiting &&
                              _investInited &&
                              (_bets.isNotEmpty || _priceBets.isNotEmpty)) {
                            // Mostrar los datos actuales mientras se refrescan
                            return Scaffold(
                              backgroundColor: Colors.transparent,
                              body: SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: ListView(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                          .padding
                                          .bottom +
                                          50,
                                    ),
                                    children: [
                                      ..._bets.reversed.map(
                                            (b) => RecentBetContainer(
                                          necessaryGain: b.necessaryGain,
                                          bet: b,
                                          onDelete: () => setState(() {
                                            _bets.removeWhere(
                                                    (x) => x.id == b.id);
                                          }),
                                          controller: widget.controller,
                                        ),
                                      ),
                                      ..._priceBets.reversed.map(
                                            (p) => RecentPriceBetContainer(
                                          priceBet: p,
                                          onDelete: () => setState(() {
                                            _priceBets.removeWhere(
                                                    (x) => x.id == p.id);
                                          }),
                                          controller: widget.controller,
                                          isForex: Common()
                                              .isTickerForex(p.ticker),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              floatingActionButton: KeyedSubtree(
                                key: _kHistory,
                                child: Transform.translate(
                                  offset: const Offset(14, 14),
                                  child: FloatingActionButton(
                                    backgroundColor: Colors.transparent
                                        .withValues(alpha: 0.1),
                                    splashColor: Colors.grey,
                                    onPressed: () {
                                      Common().vibrate();
                                      Common().applyImmersive();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                          const BetsHistoryPage(),
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      FontAwesomeIcons.clockRotateLeft,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              floatingActionButtonLocation:
                              FloatingActionButtonLocation.endFloat,
                            );
                          }

                          if (_bets.isEmpty && _priceBets.isEmpty) {
                            return Scaffold(
                              backgroundColor: Colors.transparent,
                              body: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        strings!.get('noLiveBets') ??
                                            'You have no live bets at the moment, go to the markets tab to create a new one',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.syncopate(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            child: Image.asset(
                                                'assets/new_icon.png'),
                                          ),
                                          const Icon(
                                            Icons.arrow_downward_rounded,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              floatingActionButton: KeyedSubtree(
                                key: _kHistory,
                                child: FloatingActionButton.extended(
                                  extendedPadding:
                                  const EdgeInsets.fromLTRB(
                                      6, 6, 6, 6),
                                  backgroundColor: Colors.transparent
                                      .withValues(alpha: 0.1),
                                  splashColor: Colors.grey,
                                  onPressed: () {
                                    Common().vibrate();
                                    Common().applyImmersive();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const BetsHistoryPage(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    FontAwesomeIcons.clockRotateLeft,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    strings.get('history') ?? "History",
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              floatingActionButtonLocation:
                              FloatingActionButtonLocation.endFloat,
                            );
                          }

                          return Scaffold(
                            backgroundColor: Colors.transparent,
                            body: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ListView(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .padding
                                        .bottom +
                                        50,
                                  ),
                                  children: [
                                    ..._bets.reversed.map(
                                          (b) => RecentBetContainer(
                                        necessaryGain: b.necessaryGain,
                                        bet: b,
                                        onDelete: () => setState(() {
                                          _bets.removeWhere(
                                                  (x) => x.id == b.id);
                                        }),
                                        controller: widget.controller,
                                      ),
                                    ),
                                    ..._priceBets.reversed.map(
                                          (p) => RecentPriceBetContainer(
                                        priceBet: p,
                                        onDelete: () => setState(() {
                                          _priceBets.removeWhere(
                                                  (x) => x.id == p.id);
                                        }),
                                        controller: widget.controller,
                                        isForex: Common()
                                            .isTickerForex(p.ticker),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            floatingActionButton: KeyedSubtree(
                              key: _kHistory,
                              child: Transform.translate(
                                offset: const Offset(14, 14),
                                child: FloatingActionButton(
                                  backgroundColor: Colors.transparent
                                      .withValues(alpha: 0.1),
                                  splashColor: Colors.grey,
                                  onPressed: () {
                                    Common().vibrate();
                                    Common().applyImmersive();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const BetsHistoryPage(),
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    FontAwesomeIcons.clockRotateLeft,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            floatingActionButtonLocation:
                            FloatingActionButtonLocation.endFloat,
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trendScrollController.dispose();
    _favsScrollController.dispose();
    _ticker?.dispose();
    _favsTicker?.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
