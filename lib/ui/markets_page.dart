import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:betrader/services/assets_service.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../Services/bets_service.dart';
import '../candlesticks/src/models/candle.dart';
import '../enums/financial_assets.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import '../models/favorites.dart';
import 'candlesticks_view.dart';
import 'exact_price_view.dart';
import 'layout_page.dart';

class MarketsView extends StatefulWidget {
  final MainMenuPageController controller;
  const MarketsView({super.key, required this.controller});

  @override
  MarketsViewState createState() => MarketsViewState();

  // Variables estáticas para almacenar datos precargados
  static Map<int, List<FinancialAsset>>? _preloadedAssets;
  static Map<String, double>? _preloadedPrices;
  static Map<String, double>? _preloadedPreviousPrices; // Precios anteriores para calcular porcentajes
  static Map<String, double>? _preloadedDailyGains; // Porcentajes calculados
  static Set<String>? _preloadedFavTickers;
  static bool _isPreloading = false;

  // Método estático para precargar todos los datos antes de mostrar la vista
  static Future<void> preloadAllMarketData() async {
    if (_isPreloading) {
      // Si ya se está precargando, esperar a que termine
      while (_isPreloading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isPreloading = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final dollarCurrency = prefs.getBool('dollarCurrency') ?? false;
      final currency = dollarCurrency ? 'USD' : 'EUR';
      final storage = const FlutterSecureStorage();
      
      // Cargar todos los activos CON precios (ya vienen del backend)
      final Map<int, List<FinancialAsset>> assetsPerTab = {};
      final Map<int, String> groupMapping = {
        0: 'Shares',
        1: 'Cryptos',
        2: 'Forex',
      };
      
      for (int id = 0; id < 3; id++) {
        String? theGroup = groupMapping[id];
        if (theGroup != null) {
          final newAssets = await AssetsService().getFinancialAssetsByGroup(theGroup, currency: currency);
          assetsPerTab[id] = newAssets ?? [];
        }
      }
      
      // Cargar favoritos
      final token = await storage.read(key: "sessionToken") ?? "";
      final Favorites favs = await BetsService().fetchFavouritesData(token, currency);
      final favTickers = favs.favorites
          .map((f) => f.ticker.toUpperCase().trim())
          .where((t) => t.isNotEmpty)
          .toSet();
      
      // Extraer precios directamente de los assets (ya vienen del backend)
      final allAssets = assetsPerTab.values.expand((list) => list).toList();
      final Map<String, double> prices = {};
      final Map<String, double> previousPrices = {};
      final Map<String, double> dailyGains = {};
      
      for (var asset in allAssets) {
        final tickerKey = asset.ticker.toUpperCase().trim();
        if (asset.current != null && asset.current! > 0) {
          prices[tickerKey] = asset.current!;
          if (asset.close != null && asset.close! > 0) {
            previousPrices[tickerKey] = asset.close!;
          }
          if (asset.dailyGain != null) {
            dailyGains[tickerKey] = asset.dailyGain!;
          }
        }
      }
      
      // Guardar datos precargados
      _preloadedAssets = assetsPerTab;
      _preloadedPrices = prices;
      _preloadedPreviousPrices = previousPrices;
      _preloadedDailyGains = dailyGains;
      _preloadedFavTickers = favTickers;
    } finally {
      _isPreloading = false;
    }
  }

  // Método para obtener datos precargados
  static Map<int, List<FinancialAsset>>? getPreloadedAssets() => _preloadedAssets;
  static Map<String, double>? getPreloadedPrices() => _preloadedPrices;
  static Map<String, double>? getPreloadedPreviousPrices() => _preloadedPreviousPrices;
  static Map<String, double>? getPreloadedDailyGains() => _preloadedDailyGains;
  static Set<String>? getPreloadedFavTickers() => _preloadedFavTickers;
  
  // Limpiar datos precargados
  static void clearPreloadedData() {
    _preloadedAssets = null;
    _preloadedPrices = null;
    _preloadedPreviousPrices = null;
    _preloadedDailyGains = null;
    _preloadedFavTickers = null;
  }
}

class MarketsViewState extends State<MarketsView> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final _kTabs = GlobalKey();
  final _kAnyAsset = GlobalKey();
  FinancialAsset? _anyAssetRef;
  List<String> groups = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<int, List<FinancialAsset>> assetsPerTab = {};
  Map<String, double> _assetPrices = {};
  Set<String> _loadedPriceTickers = {}; // Track qué tickers ya tienen precio cargado
  bool _isLoading = true;
  bool _hasLoadedData = false;
  Set<String> _favTickers = {};
  bool _isFavTicker(String t) => _favTickers.contains(t.toUpperCase().trim());
  static const String _pendingFlag = '__tutorial_pending__markets_v1';
  static const String _seenFlag = '__tutorial_seen__markets_v1';
  TutorialCoachMark? _coach;
  late final VoidCallback _tabListener;
  bool _dollarCurrency = false;

  void _initGroups() {
    final strings = LocalizedStrings.of(context);
    groups = [
      strings?.get('shares') ?? 'Shares',
      'Crypto',
      'Forex',
    ];
  }


  Future<void> _loadData() async {
    if (!mounted) return;
    
    // Verificar si hay datos precargados
    final preloadedAssets = MarketsView.getPreloadedAssets();
    final preloadedPrices = MarketsView.getPreloadedPrices();
    final preloadedFavTickers = MarketsView.getPreloadedFavTickers();
    
    if (preloadedAssets != null && preloadedPrices != null && preloadedFavTickers != null) {
      // Usar datos precargados
      if (!mounted) return;
      
      // Cargar la preferencia de moneda
      final prefs = await SharedPreferences.getInstance();
      final dollarCurrency = prefs.getBool('dollarCurrency') ?? false;
      
      if (!mounted) return;
      setState(() {
        assetsPerTab = Map.from(preloadedAssets);
        _assetPrices = Map.from(preloadedPrices);
        _favTickers = Set.from(preloadedFavTickers);
        _loadedPriceTickers = _assetPrices.keys.toSet();
        _dollarCurrency = dollarCurrency;
        _isLoading = false;
      });
    } else {
      // Cargar datos normalmente si no hay precarga
      await _loadAllAssets();
      if (!mounted) return;
      
      await _loadFavorites();
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final dollarCurrency = prefs.getBool('dollarCurrency') ?? false;
    final currency = dollarCurrency ? 'USD' : 'EUR';
    
    Map<int, String> groupMapping = {
      0: 'Shares',
      1: 'Cryptos',
      2: 'Forex',
    };

    for (int id = 0; id < groups.length; id++) {
      String? theGroup = groupMapping[id];
      if (theGroup != null) {
        final newAssets = await AssetsService().getFinancialAssetsByGroup(theGroup, currency: currency);
        assetsPerTab[id] = newAssets ?? [];
      }
    }
    
    // Los precios ya vienen en los assets, extraerlos
    if (!mounted) return;
    
    final Map<String, double> prices = {};
    final allAssets = assetsPerTab.values.expand((list) => list).toList();
    
    for (var asset in allAssets) {
      final tickerKey = asset.ticker.toUpperCase().trim();
      if (asset.current != null && asset.current! > 0) {
        prices[tickerKey] = asset.current!;
        _loadedPriceTickers.add(tickerKey);
      }
    }
    
    if (!mounted) return;
    setState(() {
      _assetPrices = prices;
    });
  }


  Future<void> _loadFavorites() async {
    if (!mounted) return;
    
    final token = await _storage.read(key: "sessionToken") ?? "";
    final prefs = await SharedPreferences.getInstance();

    final dollarCurrency = prefs.getBool('dollarCurrency') ?? false;
    final Favorites favs = await BetsService().fetchFavouritesData(token, (dollarCurrency ? 'USD' : 'EUR'));
    
    if (!mounted) return;
    
    final tickers = favs.favorites
        .map((f) => f.ticker.toUpperCase().trim())
        .where((t) => t.isNotEmpty)
        .toSet();
    
    if (!mounted) return;
    
    setState(() {
      _favTickers = tickers;
      _dollarCurrency = dollarCurrency;
    });
  }

  Future<void> _showAssetDetails(BuildContext context, FinancialAsset a) async {
    final strings = LocalizedStrings.of(context);
    final Color textColor = Colors.white;

    final groupPretty = _prettyGroup(a.group, strings);

    final rows = <Widget>[
      _kvRow(strings?.get('name') ?? 'Name', a.name.length > 10 ? a.name.substring(0,10) : a.name, textColor),
      const Divider(),
      _kvRow('Ticker', a.ticker, textColor),
      const Divider(),
      _kvRow(strings?.get('type') ?? 'Type', groupPretty, textColor),
      const Divider(),
      _kvRow(strings?.get('country') ?? 'Country', a.country.isEmpty ? '—' : a.country, textColor, showCountryFlag: true),
    ];

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent.withValues(alpha: 0.1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white70.withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .6),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (a.icon.isNotEmpty) ...[
                          Center(child: _assetIcon(a, size: 120)),
                          const SizedBox(height: 12),
                        ],
                        ...rows,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

  }

  bool isFavorite(String ticker) {
    return _favTickers.contains(ticker);
  }

  void toggleFavorite(String ticker, {bool onlyLocal = false}) async {
    final key = ticker.toUpperCase().trim();

    if (onlyLocal) {
      if (!mounted) return;
      setState(() {
        if (_favTickers.contains(key)) {
          _favTickers.remove(key);
        } else {
          _favTickers.add(key);
        }
      });

      homeScreenKey.currentState?.refreshFavorites();
      return;
    }

    if (mounted) {
      setState(() {
        if (_favTickers.contains(key)) {
          _favTickers.remove(key);
        } else {
          _favTickers.add(key);
        }
      });
    }

    final token = await _storage.read(key: "sessionToken") ?? "none";
    final ok = await BetsService().postNewFavorite(token, ticker);

    if (!ok && mounted) {
      setState(() {
        if (_favTickers.contains(key)) {
          _favTickers.remove(key);
        } else {
          _favTickers.add(key);
        }
      });
      Common().showFloatingSnack(context, "Error updating favorites", backgroundColor: Colors.red);
    } else {
      if (mounted) {
        await _loadFavorites();
      }
    }

    homeScreenKey.currentState?.refreshFavorites();
  }

  Widget _buildLeafCardLayout(List<FinancialAsset> assets) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // Los precios ya vienen en los assets, no necesitamos cargar más
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final asset = assets[index];
          final isFav = _favTickers.contains(asset.ticker.toUpperCase().trim());
          Widget card = _buildLeafCard(asset: asset, isFav: isFav, index: index);
          
          // Los precios ya vienen en los assets del backend, no necesitamos cargarlos
          
          if (index == 0 && _kAnyAsset.currentContext == null) {
            _anyAssetRef ??= asset;
            card = KeyedSubtree(key: _kAnyAsset, child: card);
          }
          
          return card;
        },
      ),
    );
  }

  Widget _buildLeafCard({
    required FinancialAsset asset,
    required bool isFav,
    required int index,
  }) {
    return _LeafCardWidget(
      key: ValueKey(asset.ticker),
      asset: asset,
      isFav: isFav,
      index: index,
      dollarCurrency: _dollarCurrency,
      onAssetChart: _openAssetChart,
      onToggleFavorite: toggleFavorite,
      onShowDetails: _showAssetDetails,
      assetFallbackBadge: _assetFallbackBadge,
    );
  }

  Widget _kvRow(String k, String v, Color textColor, {showCountryFlag = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              k,
              style: GoogleFonts.montserrat(
                color: textColor.withValues(alpha: .85),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Text(
                  (v.isEmpty ? '—' : v),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.roboto(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (showCountryFlag && v != "World") ... [
                  SizedBox(width: 8),
                  CountryFlag.fromCountryCode(
                    Common().getCountryCode(v),
                    height: 18,
                    width: 25,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetIcon(FinancialAsset a, {double size = 40}) {
    try {
      if (a.icon.isNotEmpty && !a.icon.startsWith('http')) {
        // Base64
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 4),
          child:
          Image.memory(
            base64Decode(a.icon),
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _assetFallbackBadge(a, size),
          ),
        );
      } else if (a.icon.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 4),
          child: Image.network(
            a.icon,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _assetFallbackBadge(a, size),
          ),
        );
      }
    } catch (_) {
    }
    return _assetFallbackBadge(a, size);
  }

  Widget _assetFallbackBadge(FinancialAsset a, double size) {
    final text = (a.ticker.isNotEmpty ? a.ticker : a.name).toUpperCase();
    final short = text.length <= 4 ? text : text.substring(0, 4);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(size / 4),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        short,
        style: GoogleFonts.montserrat(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w300,
          color: Colors.white,
        ),
      ),
    );
  }

  String _prettyGroup(String group, LocalizedStrings? strings) {
    final g = group.toLowerCase();
    if (g.contains('crypto')) {
      return 'Crypto';
    } else if (g.contains('share') || g.contains('stock') || g == 'shares') {
      return strings?.get('shares') ?? 'Shares';
    } else if (g.contains('forex') || g == 'forex') {
      return 'Forex';
    }
    return group;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);

    _tabListener = () {
      if (widget.controller.selectedIndexNotifier.value == 2) {
        _tryStartMarketsTutorial();
      }
    };
    widget.controller.selectedIndexNotifier.addListener(_tabListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.selectedIndexNotifier.value == 2) {
        _tryStartMarketsTutorial();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.selectedIndexNotifier.removeListener(_tabListener);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted && !_hasLoadedData) {
      _initGroups();
      _loadData();
      _hasLoadedData = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      verticalDirection: VerticalDirection.up,
      children: [
        TabBar(
          key: _kTabs,
          onTap: (_) => Common().applyImmersive(),
          indicatorColor: Colors.purple,
          labelColor: Colors.white,
          dividerColor: Colors.white30,
          tabAlignment: TabAlignment.center,
          isScrollable: true,
          controller: _tabController,
          labelStyle: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w400,
          ),
          labelPadding: const EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
          unselectedLabelStyle: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
          tabs: groups.map((String group) => Tab(text: group)).toList(),
        ),
        const Divider(
          color: Colors.white30,
          thickness: 2,
          height: 1,
        ),
        Expanded(
          child: _isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: 10,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: List.generate(groups.length, (index) {
                    final List<FinancialAsset> assets = List.from(assetsPerTab[index] ?? []);
                    // Ordenar: favoritos primero, luego por precio descendente
                    assets.sort((a, b) {
                      final aIsFav = _isFavTicker(a.ticker);
                      final bIsFav = _isFavTicker(b.ticker);
                      
                      // Favoritos primero
                      if (aIsFav && !bIsFav) return -1;
                      if (!aIsFav && bIsFav) return 1;
                      
                      // Si ambos son favoritos o ambos no lo son, ordenar por precio
                      final aTicker = a.ticker.toUpperCase().trim();
                      final bTicker = b.ticker.toUpperCase().trim();
                      final aPrice = _assetPrices[aTicker];
                      final bPrice = _assetPrices[bTicker];
                      
                      // Si ambos tienen precio, ordenar descendente
                      if (aPrice != null && bPrice != null) {
                        return bPrice.compareTo(aPrice);
                      }
                      // Si solo uno tiene precio, el que tiene precio va primero
                      if (aPrice != null && bPrice == null) return -1;
                      if (aPrice == null && bPrice != null) return 1;
                      // Si ninguno tiene precio, mantener orden original
                      return 0;
                    });
                    return _buildLeafCardLayout(assets);
                  }),
                ),
        ),
      ],
    );
  }

  //------ T U T O R I A L      M E T H O D S -----
  Future<void> _markSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_seenFlag, true);
  }

  Future<void> _clearPending() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_pendingFlag);
  }

  Future<void> _waitForTargetsReady() async {
    for (int i = 0; i < 30; i++) {
      final ready = _kTabs.currentContext != null && _kAnyAsset.currentContext != null;
      if (ready) break;
    }
  }

  List<TargetFocus> _buildMarketsTargets(LocalizedStrings? strings) {
    return [
      TargetFocus(
        identify: 'mv_tabs',
        keyTarget: _kTabs,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => Common().bubble(
                strings!.get('mv_tabs_title') ?? 'Different markets',
                strings.get('mv_tabs_body') ??
                    'Switch between different markets: Shares, Crypto, and Forex. Tabs are scrollable and remember your last selection. Assets are displayed in their original order, and data refreshes automatically during the session.'
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: 'mv_anyasset',
        keyTarget: _kAnyAsset,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => Common().bubble(
                strings!.get('mv_anyasset_title') ?? 'Asset',
                strings.get('mv_anyasset_body') ??
                    'Tap to open the candlestick chart with full timeframe control. Long press for quick actions like adding to favorites, placing exact-price bets, setting alerts, or viewing details.'
            ),
          ),
        ],
      ),

    ];
  }

  Future<void> _tryStartMarketsTutorial() async {

    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_pendingFlag) ?? false;
    if (!pending) return;

    await _waitForTargetsReady();

    if (widget.controller.selectedIndexNotifier.value != 2) return;
    await _startMarketsTutorial();
  }

  Future<void> _openAssetChart(FinancialAsset asset, {bool tutorialMode = false}) async {
    Common().vibrate();
    Common().applyImmersive();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      enableDrag: !tutorialMode,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.56,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Expanded(
                    child: CandlesticksView(
                      ticker: asset.ticker,
                      name: asset.name,
                      controller: widget.controller,
                      iconPath: asset.icon,
                      tutorialMode: tutorialMode
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

  }

  Future<void> _startMarketsTutorial() async {
    final strings = LocalizedStrings.of(context);
    final targets = _buildMarketsTargets(strings)
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
      onClickTarget: (target) async {
        try {
          if (target.identify == 'mv_anyasset' && _anyAssetRef != null) {
            final p = await SharedPreferences.getInstance();
            await p.setBool('__tutorial_pending__candles_v1', true);

            try { _coach?.finish(); } catch (_) {}
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _anyAssetRef != null) {
                _openAssetChart(_anyAssetRef!, tutorialMode: true);
              }
            });
          }
        } catch (_) {}
      },
      onClickOverlay: (_) {},
      onSkip: () {
        _clearPending();
        _markSeen();
        Common().markAllTutorialsSeen();
        return true;
      },
      onFinish: () async {
        await Future.delayed(const Duration(milliseconds: 150));
        await _clearPending();
        await _markSeen();
      },
    );

    _coach!.show(context: context);
  }

}

//------ ARC SELECTOR WIDGET

class ArcSelector extends StatefulWidget {
  final List<FinancialAsset?> assets;
  final Function(FinancialAsset) onAssetTap;
  final Function(FinancialAsset) onAssetLongPress;
  final bool Function(String) isFavorite;
  final Widget Function() buildFavBadge;
  final Widget Function(FinancialAsset, {double size}) assetIcon;
  final bool dollarCurrency;
  final GlobalKey kAnyAsset;
  final FinancialAsset? anyAssetRef;
  final Function(FinancialAsset?) onAnyAssetSet;
  final bool isSkeleton;

  const ArcSelector({
    super.key,
    required this.assets,
    required this.onAssetTap,
    required this.onAssetLongPress,
    required this.isFavorite,
    required this.buildFavBadge,
    required this.assetIcon,
    required this.dollarCurrency,
    required this.kAnyAsset,
    required this.anyAssetRef,
    required this.onAnyAssetSet,
    this.isSkeleton = false,
  });

  @override
  State<ArcSelector> createState() => _ArcSelectorState();
}

class _ArcSelectorState extends State<ArcSelector> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Animation<double>? _rotationAnimation;
  
  double _dragStartX = 0.0;
  double _dragStartRotation = 0.0;
  double _velocity = 0.0;
  DateTime _lastUpdate = DateTime.now();
  double _lastIndex = 0.0;
  VoidCallback? _animationListener;
  
  static const double _rotationSensitivity = 0.02; // Sensibilidad de rotación
  static const double _friction = 0.92; // Fricción para inercia
  static const double _minVelocity = 0.5; // Velocidad mínima para continuar
  static const int _visibleItems = 5; // Número de elementos visibles a la vez
  
  // Índice base que representa el elemento central
  double _baseIndex = 0.0; // Usamos double para permitir valores fraccionarios durante animación

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _lastUpdate = DateTime.now();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    _animationController.stop();
    _animationController.reset();
    _dragStartX = details.globalPosition.dx;
    _dragStartRotation = _baseIndex;
    _velocity = 0.0;
    _lastIndex = _baseIndex;
    _lastUpdate = DateTime.now();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final now = DateTime.now();
    final deltaTime = now.difference(_lastUpdate).inMilliseconds / 1000.0;
    
    if (deltaTime > 0 && widget.assets.isNotEmpty) {
      final deltaX = details.globalPosition.dx - _dragStartX;
      // Convertir desplazamiento horizontal a cambio de índice
      final newIndex = _dragStartRotation - (deltaX * _rotationSensitivity);
      
      final deltaIndex = newIndex - _lastIndex;
      _velocity = deltaTime > 0 ? (deltaIndex / deltaTime) * 0.3 : 0.0;
      
      setState(() {
        _baseIndex = newIndex.clamp(0.0, (widget.assets.length - 1).toDouble());
        _lastIndex = _baseIndex;
        _lastUpdate = now;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    // Aplicar inercia basada en la velocidad
    if (_velocity.abs() > _minVelocity) {
      _applyInertia();
    } else {
      _snapToNearest();
    }
  }

  void _applyInertia() {
    _animationController.stop();
    _animationController.reset();
    
    // Remover listener anterior si existe
    if (_animationListener != null && _rotationAnimation != null) {
      _rotationAnimation!.removeListener(_animationListener!);
    }
    
    // Calcular distancia de inercia basada en velocidad
    double distance = 0.0;
    double currentVelocity = _velocity.abs();
    while (currentVelocity > _minVelocity) {
      distance += currentVelocity * 0.1;
      currentVelocity *= _friction;
    }
    
    final direction = _velocity > 0 ? 1.0 : -1.0;
    final targetIndex = _baseIndex + (distance * direction);
    final clampedTarget = targetIndex.clamp(0.0, (widget.assets.length - 1).toDouble());
    
    final tween = Tween<double>(
      begin: _baseIndex,
      end: clampedTarget,
    );
    
    _rotationAnimation = tween.animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.decelerate,
    ));
    
    _animationListener = () {
      if (_rotationAnimation != null) {
        setState(() {
          _baseIndex = _rotationAnimation!.value.clamp(0.0, (widget.assets.length - 1).toDouble());
        });
      }
    };
    
    _rotationAnimation!.addListener(_animationListener!);
    
    _animationController.forward().then((_) {
      if (_rotationAnimation != null && _animationListener != null) {
        _rotationAnimation!.removeListener(_animationListener!);
      }
      _snapToNearest();
    });
  }

  void _snapToNearest() {
    if (widget.assets.isEmpty || widget.isSkeleton) return;
    
    // Remover listener anterior si existe
    if (_animationListener != null && _rotationAnimation != null) {
      _rotationAnimation!.removeListener(_animationListener!);
    }
    
    // Snap al índice más cercano
    final targetIndex = _baseIndex.round().clamp(0, widget.assets.length - 1).toDouble();
    
    final tween = Tween<double>(
      begin: _baseIndex,
      end: targetIndex,
    );
    
    _rotationAnimation = tween.animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationListener = () {
      if (_rotationAnimation != null) {
        setState(() {
          _baseIndex = _rotationAnimation!.value.clamp(0.0, (widget.assets.length - 1).toDouble());
        });
      }
    };
    
    _rotationAnimation!.addListener(_animationListener!);
    _animationController.forward().then((_) {
      if (_rotationAnimation != null && _animationListener != null) {
        _rotationAnimation!.removeListener(_animationListener!);
      }
    });
  }

  // Determinar qué elementos están visibles
  List<int> _getVisibleIndices() {
    if (widget.assets.isEmpty) return [];
    
    final centerOffset = (_visibleItems - 1) / 2;
    final baseIndexInt = _baseIndex.round();
    
    // Obtener índices visibles alrededor del base (2 antes, base, 2 después = 5 total)
    final visibleIndices = <int>[];
    for (int i = 0; i < _visibleItems; i++) {
      final index = baseIndexInt + i - centerOffset.round();
      if (index >= 0 && index < widget.assets.length) {
        visibleIndices.add(index);
      }
    }
    
    return visibleIndices;
  }

  Widget _buildAssetTile(FinancialAsset? asset, int assetIndex, int positionInVisible, Size size) {
    if (asset == null && !widget.isSkeleton) return const SizedBox.shrink();
    
    // Parámetros del arco
    final centerX = size.width / 2;
    final centerY = size.height * 0.35;
    final radius = math.min(size.width, size.height) * 0.38;
    
    // Arco semicircular de 180 grados
    final startAngle = -math.pi / 2; // -90 grados (arriba)
    final arcAngle = math.pi; // 180 grados
    final anglePerItem = arcAngle / (_visibleItems - 1);
    final centerOffset = (_visibleItems - 1) / 2.0;
    
    // Calcular posición relativa del elemento en el arco visible
    final relativePosition = positionInVisible - centerOffset;
    
    // Calcular el offset fraccional desde el índice base
    final fractionalOffset = _baseIndex - _baseIndex.round();
    
    // Ángulo del elemento ajustado por el offset fraccional
    final adjustedPosition = relativePosition - fractionalOffset;
    final itemAngle = startAngle + (centerOffset * anglePerItem) + (adjustedPosition * anglePerItem);
    
    // Normalizar al rango [0, 2π]
    final normalizedAngle = (itemAngle % (math.pi * 2) + (math.pi * 2)) % (math.pi * 2);
    
    // Calcular posición en el arco
    final x = centerX + radius * math.cos(normalizedAngle);
    final y = centerY + radius * math.sin(normalizedAngle);
    
    // Tamaño del tile
    const tileSize = 110.0;
    const tileHalf = tileSize / 2;

    // Calcular escala y opacidad basada en la distancia del centro
    final distanceFromCenter = adjustedPosition.abs();
    final maxDistance = centerOffset;
    final normalizedDistance = distanceFromCenter / maxDistance;
    final scale = 0.65 + (1.0 - normalizedDistance.clamp(0.0, 1.0)) * 0.35; // 0.65x a 1.0x
    final opacity = 0.4 + (1.0 - normalizedDistance.clamp(0.0, 1.0)) * 0.6; // 0.4 a 1.0
    
    if (widget.isSkeleton || asset == null) {
      return Positioned(
        left: x - tileHalf,
        top: y - tileHalf,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: SizedBox(
              width: tileSize,
              height: tileSize,
              child: const SkeletonAssetContainer(),
            ),
          ),
        ),
      );
    }

    final isFav = widget.isFavorite(asset.ticker);

    Widget tile = Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          clipBehavior: Clip.antiAlias,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            highlightColor: Colors.white.withValues(alpha: .18),
            splashColor: Colors.white.withValues(alpha: .10),
            onTap: () => widget.onAssetTap(asset),
            onLongPress: () => widget.onAssetLongPress(asset),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.transparent.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white10,
                    blurRadius: 5.0,
                    spreadRadius: 2.0,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (asset.icon.isNotEmpty &&
                          asset.icon != "null" &&
                          !asset.icon.contains("http")) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            base64Decode(asset.icon),
                            height: 55,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) => Text(
                              asset.name,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                fontSize: 36,
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                          ),
                        )
                      ] else if (asset.icon.isNotEmpty &&
                          asset.icon.contains("http")) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            asset.icon,
                            height: 55,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) => Text(
                              Common().createTrendViewNameFromName(asset.name),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                fontSize: 36,
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                          ),
                        )
                      ] else ...[
                        Text(
                          Common().createTrendViewNameFromName(asset.name),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 36,
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        asset.name,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isFav)
          Positioned(
            top: -7,
            left: -10,
            child: widget.buildFavBadge(),
          ),
      ],
    );

    if (assetIndex == 0 && widget.kAnyAsset.currentContext == null) {
      widget.onAnyAssetSet(asset);
      tile = KeyedSubtree(key: widget.kAnyAsset, child: tile);
    }

    return Positioned(
      left: x - tileHalf,
      top: y - tileHalf,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: tileSize,
            height: tileSize,
            child: tile,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        // Obtener solo los índices visibles
        final visibleIndices = widget.isSkeleton 
            ? List.generate(math.min(_visibleItems, widget.assets.length), (i) => i)
            : _getVisibleIndices();
        
        return GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (!widget.isSkeleton)
                CustomPaint(
                  size: size,
                  painter: _ArcPainter(),
                ),
              ...visibleIndices.asMap().entries.map((entry) {
                final positionInVisible = entry.key;
                final assetIndex = entry.value;
                return _buildAssetTile(
                  widget.assets[assetIndex],
                  assetIndex,
                  positionInVisible,
                  size,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Opcional: dibujar guía del arco si se necesita
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height * 0.3);
    final radius = math.min(size.width, size.height) * 0.32;
    
    // Dibujar arco guía (semicírculo superior)
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

//------ LEAF CARD WIDGET

class _LeafCardWidget extends StatefulWidget {
  final FinancialAsset asset;
  final bool isFav;
  final int index;
  final bool dollarCurrency;
  final Function(FinancialAsset) onAssetChart;
  final Function(String) onToggleFavorite;
  final Function(BuildContext, FinancialAsset) onShowDetails;
  final Widget Function(FinancialAsset, double) assetFallbackBadge;

  const _LeafCardWidget({
    super.key,
    required this.asset,
    required this.isFav,
    required this.index,
    required this.dollarCurrency,
    required this.onAssetChart,
    required this.onToggleFavorite,
    required this.onShowDetails,
    required this.assetFallbackBadge,
  });

  @override
  State<_LeafCardWidget> createState() => _LeafCardWidgetState();
}

class _LeafCardWidgetState extends State<_LeafCardWidget> {
  double? _closePrice;
  double? _currentPrice;
  double? _dailyGain;
  bool _isLoadingPrice = true;
  String _currency = '€';

  @override
  void initState() {
    super.initState();
    _currency = widget.dollarCurrency ? '\$' : '€';
    _loadPriceData();
  }

  Future<void> _loadPriceData() async {
    // Verificar si hay precio precargado disponible
    final preloadedPrices = MarketsView.getPreloadedPrices();
    final preloadedPreviousPrices = MarketsView.getPreloadedPreviousPrices();
    final preloadedDailyGains = MarketsView.getPreloadedDailyGains();
    final tickerKey = widget.asset.ticker.toUpperCase().trim();
    
    if (preloadedPrices != null && preloadedPrices.containsKey(tickerKey)) {
      // Usar datos precargados completos (precio actual, anterior y porcentaje)
      final preloadedPrice = preloadedPrices[tickerKey]!;
      final preloadedPrevious = preloadedPreviousPrices?[tickerKey];
      final preloadedGain = preloadedDailyGains?[tickerKey];
      
      if (mounted) {
        setState(() {
          _currentPrice = preloadedPrice;
          _closePrice = preloadedPrevious;
          _dailyGain = preloadedGain;
          _isLoadingPrice = false;
        });
      }
    } else {
      // Cargar precios normalmente si no hay precarga
      try {
        final candles = await BetsService().fetchCandles(
          widget.asset.ticker,
          1,
          widget.dollarCurrency ? 'USD' : 'EUR',
        );
        
        if (mounted && candles.isNotEmpty) {
          final currentCandle = candles.first;
          final previousCandle = candles.length > 1 ? candles[1] : currentCandle;
          
          // Validar que los precios sean válidos y no sospechosos
          final currentPrice = currentCandle.close;
          final previousPrice = previousCandle.close;
          
          // Intentar cargar al menos el precio actual
          if (currentPrice > 0 &&
              currentPrice.isFinite &&
              !currentPrice.isNaN &&
              currentPrice != 1.0) {
            if (previousPrice > 0 &&
                previousPrice.isFinite &&
                !previousPrice.isNaN &&
                previousPrice != 1.0 &&
                !(currentPrice == 1.0 && previousPrice == 1.0)) {
              // Tenemos ambos precios válidos
              setState(() {
                _currentPrice = currentPrice;
                _closePrice = previousPrice;
                _dailyGain = ((_currentPrice! - _closePrice!) / _closePrice!) * 100;
                _isLoadingPrice = false;
              });
            } else {
              // Solo tenemos precio actual válido
              setState(() {
                _currentPrice = currentPrice;
                _isLoadingPrice = false;
              });
            }
          } else {
            // Si los precios no son válidos, marcar como no cargado
            if (mounted) {
              setState(() {
                _isLoadingPrice = false;
              });
            }
          }
        } else {
          // No hay velas disponibles
          if (mounted) {
            setState(() {
              _isLoadingPrice = false;
            });
          }
        }
      } catch (e) {
        // Error al cargar precios
        if (mounted) {
          setState(() {
            _isLoadingPrice = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rotation = (widget.index % 3 - 1) * 0.5;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 40).clamp(0, 800)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Transform.rotate(
          angle: rotation * 3.14159 / 180,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                clipBehavior: Clip.none,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  highlightColor: Colors.white.withValues(alpha: .1),
                  splashColor: Colors.white.withValues(alpha: .05),
                  onTap: () {
                    widget.onAssetChart(widget.asset);
                  },
                  onLongPress: () {
                    Common().vibrate();
                    Common().applyImmersive();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.black.withValues(alpha: 0.75),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (BuildContext context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                dense: false,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Icon(
                                  widget.isFav ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
                                  color: Colors.white70,
                                ),
                                title: Text(
                                  (widget.isFav
                                      ? LocalizedStrings.of(context)!.get('removeFromFavorites')!
                                      : LocalizedStrings.of(context)!.get('addToFavorites')!),
                                  style: GoogleFonts.montserrat(),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onToggleFavorite(widget.asset.ticker);
                                },
                              ),
                              ListTile(
                                dense: false,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: const Icon(FontAwesomeIcons.crosshairs),
                                title: Text(
                                  LocalizedStrings.of(context)!.get('exactPriceBets') ?? "Exact price bets",
                                  style: GoogleFonts.montserrat(),
                                ),
                                onTap: () async {
                                  List<Candle> candles = await BetsService().fetchCandles(
                                    widget.asset.ticker,
                                    1,
                                    widget.dollarCurrency ? 'USD' : 'EUR',
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExactPricePage(
                                        name: widget.asset.name,
                                        ticker: widget.asset.ticker,
                                        currentValue: candles.first.close,
                                        iconPath: widget.asset.icon,
                                        isForex: widget.asset.group.toLowerCase() == "forex",
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                dense: false,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                leading: const Icon(Icons.notifications_none),
                                title: Text(
                                  LocalizedStrings.of(context)!.get('createAlert') ?? "Create alert",
                                  style: GoogleFonts.montserrat(),
                                ),
                                onTap: () {
                                  Common().showFloatingSnack(context, "Unimplemented action!", backgroundColor: Colors.black54);
                                  Navigator.pop(context);
                                }
                              ),
                              ListTile(
                                dense: false,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: const Icon(Icons.info_outline),
                                title: Text(
                                  LocalizedStrings.of(context)!.get('viewDetails') ?? "View details",
                                  style: GoogleFonts.montserrat()),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onShowDetails(context, widget.asset);
                                }
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isFav
                          ? Colors.amber.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.isFav
                            ? Colors.yellow.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                        if (widget.isFav)
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 0),
                          ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 25.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Información en dos líneas centradas
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Primera línea: Nombre
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.asset.name.split(' ').take(2).join(' '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.syncopate(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        if (widget.isFav) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            FontAwesomeIcons.solidStar,
                                            size: 14,
                                            color: Colors.yellow,
                                          ),
                                        ],
                                      ],
                                    ),
                                    // Segunda línea: Precios centrados
                                    if (!_isLoadingPrice && _currentPrice != null)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          if (_closePrice != null) ...[
                                            Text(
                                              '${(_closePrice! > 1 ? _closePrice!.toStringAsFixed(2) : _closePrice!.toStringAsFixed(4))}$_currency',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '→',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white54,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            '${(_currentPrice! > 1 ? _currentPrice!.toStringAsFixed(2) : _currentPrice!.toStringAsFixed(4))}$_currency',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: _dailyGain != null && _dailyGain! >= 0.0 ? const Color(0xFF059669) : (_dailyGain != null ? const Color(0xFFDC2626) : Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Indicador de porcentaje destacado
                          if (!_isLoadingPrice && _dailyGain != null)
                            Positioned(
                              right: 8,
                              top: 0,
                              bottom: 0,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Transform.translate(
                                  offset: const Offset(0, 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      (_dailyGain! >= 0.0)
                                          ? Icon(
                                              FontAwesomeIcons.arrowTrendUp,
                                              color: const Color(0xFF059669),
                                              size: 18,
                                            )
                                          : Icon(
                                              FontAwesomeIcons.arrowTrendDown,
                                              color: const Color(0xFFDC2626),
                                              size: 18,
                                            ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_dailyGain!.abs().toStringAsFixed(2)}%',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _dailyGain! >= 0.0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                          shadows: [
                                            Shadow(
                                              color: (_dailyGain! >= 0.0 ? const Color(0xFF059669) : const Color(0xFFDC2626)).withValues(alpha: 0.5),
                                              blurRadius: 8,
                                              offset: const Offset(0, 0),
                                            ),
                                          ],
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
                  ),
                ),
              ),
              // Icono que sobresale por la izquierda
              Positioned(
                left: 0,
                top: -15,
                bottom: -15,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.asset.icon.isNotEmpty &&
                            widget.asset.icon != "null" &&
                            !widget.asset.icon.contains("http")
                        ? Image.memory(
                            base64Decode(widget.asset.icon),
                            width: 60,
                            height: 60,
                            fit: BoxFit.fitHeight,
                            errorBuilder: (_, __, ___) => widget.assetFallbackBadge(widget.asset, 60),
                          )
                        : widget.asset.icon.isNotEmpty && widget.asset.icon.contains("http")
                            ? Image.network(
                                widget.asset.icon,
                                width: 65,
                                height: 65,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => widget.assetFallbackBadge(widget.asset, 60),
                              )
                            : widget.assetFallbackBadge(widget.asset, 65),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//------ SKELETON

class SkeletonAssetContainer extends StatelessWidget {
  const SkeletonAssetContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
