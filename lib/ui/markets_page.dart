import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:betrader/services/assets_service.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../services/bets_service.dart';
import '../candlesticks/src/models/candle.dart';
import '../enums/financial_assets.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import '../models/favorites.dart';
import 'candlesticks_view.dart';
import 'exact_price_view.dart';
import 'layout_page.dart';

/// Criterios de ordenación de la lista de mercados.
enum MarketsSortOrder {
  alphabet,
  value,
  odd,
}

/// A view displaying financial markets organized by asset type (Shares, Crypto, Forex).
///
/// Supports data preloading for faster initial load, displays assets in tabs,
/// and provides functionality to view charts, add favorites, and place bets.
class MarketsView extends StatefulWidget {
  /// Controller for managing the main menu navigation.
  final MainMenuPageController controller;
  const MarketsView({super.key, required this.controller});

  @override
  MarketsViewState createState() => MarketsViewState();

  // Variables estaticas para almacenar datos precargados
  static Map<int, List<FinancialAsset>>? _preloadedAssets;
  static Map<String, double>? _preloadedPrices;
  static Map<String, double>? _preloadedPreviousPrices; // Precios anteriores para calcular porcentajes
  static Map<String, double>? _preloadedDailyGains; // Porcentajes calculados
  static Set<String>? _preloadedFavTickers;
  /// Max odds por ticker y timeframe (1, 2, 4, 24) desde backend.
  static Map<String, Map<int, ({double maxOdd, int direction, int zoneId})>>? _preloadedMaxOdds;
  static bool _isPreloading = false;

  /// Preloads all market data before displaying the view.
  ///
  /// Fetches assets for all tabs (Shares, Crypto, Forex), prices, and favorites.
  /// This method is typically called during login to improve perceived performance.
  /// If already preloading, waits for the current preload to complete.
  static Future<void> preloadAllMarketData() async {
    if (_isPreloading) {
      // Si ya se esta precargando, esperar a que termine
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

      // Cargar max odds por ticker/timeframe (requiere token)
      Map<String, Map<int, ({double maxOdd, int direction, int zoneId})>>? maxOddsMap;
      if (token.isNotEmpty) {
        try {
          maxOddsMap = await BetsService().fetchMaxOdds(currency);
        } catch (_) {
          maxOddsMap = null;
        }
      }

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
      _preloadedMaxOdds = maxOddsMap;
    } finally {
      _isPreloading = false;
    }
  }

  /// Gets preloaded assets data organized by tab index.
  static Map<int, List<FinancialAsset>>? getPreloadedAssets() => _preloadedAssets;
  
  /// Gets preloaded current prices map (ticker -> price).
  static Map<String, double>? getPreloadedPrices() => _preloadedPrices;
  
  /// Gets preloaded previous day closing prices map (ticker -> price).
  static Map<String, double>? getPreloadedPreviousPrices() => _preloadedPreviousPrices;
  
  /// Gets preloaded daily gain percentages map (ticker -> percentage).
  static Map<String, double>? getPreloadedDailyGains() => _preloadedDailyGains;
  
  /// Gets preloaded favorite tickers set.
  static Set<String>? getPreloadedFavTickers() => _preloadedFavTickers;

  /// Gets preloaded max odds by ticker and timeframe (1, 2, 4, 24).
  static Map<String, Map<int, ({double maxOdd, int direction, int zoneId})>>? getPreloadedMaxOdds() => _preloadedMaxOdds;

  /// Updates only max odds (e.g. from periodic refresh). Does not clear other preloaded data.
  static void updatePreloadedMaxOdds(Map<String, Map<int, ({double maxOdd, int direction, int zoneId})>>? value) {
    _preloadedMaxOdds = value;
  }

  /// Clears all preloaded market data.
  ///
  /// Should be called when data becomes stale or when memory needs to be freed.
  static void clearPreloadedData() {
    _preloadedAssets = null;
    _preloadedPrices = null;
    _preloadedPreviousPrices = null;
    _preloadedDailyGains = null;
    _preloadedFavTickers = null;
    _preloadedMaxOdds = null;
  }
}

class MarketsViewState extends State<MarketsView> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final _kTabs = GlobalKey();
  /// Una GlobalKey por tab para el primer ítem; evita "key specified multiple times" al cambiar de tab.
  final List<GlobalKey> _kAnyAssetByTab = List.generate(3, (_) => GlobalKey());
  FinancialAsset? _anyAssetRef;
  List<String> groups = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<int, List<FinancialAsset>> assetsPerTab = {};
  Map<String, double> _assetPrices = {};
  Set<String> _loadedPriceTickers = {}; // Track tickers ya tienen precio cargado
  bool _isLoading = true;
  bool _hasLoadedData = false;
  Set<String> _favTickers = {};
  bool _isFavTicker(String t) => _favTickers.contains(t.toUpperCase().trim());
  static const String _pendingFlag = '__tutorial_pending__markets_v1';
  static const String _seenFlag = '__tutorial_seen__markets_v1';
  TutorialCoachMark? _coach;
  late final VoidCallback _tabListener;
  bool _dollarCurrency = false;
  final Map<int, ScrollController> _scrollControllers = {};
  MarketsSortOrder _sortOrder = MarketsSortOrder.value;

  void _initGroups() {
    final strings = LocalizedStrings.of(context);
    groups = [
      strings?.get('shares') ?? 'Shares',
      'Crypto',
      'Forex',
    ];
  }

  /// Refreshes max odds from the server and updates the UI. Called periodically from HomeScreen timer.
  Future<void> refreshMaxOdds() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final dollarCurrency = prefs.getBool('dollarCurrency') ?? false;
      final currency = dollarCurrency ? 'USD' : 'EUR';
      final token = await _storage.read(key: 'sessionToken') ?? '';
      if (token.isEmpty) return;
      final map = await BetsService().fetchMaxOdds(currency);
      if (!mounted) return;
      MarketsView.updatePreloadedMaxOdds(map);
      setState(() {});
    } catch (_) {
      // Silently ignore; next cycle will retry
    }
  }

  /// Loads market data, preferring preloaded data if available.
  ///
  /// If preloaded data exists, uses it immediately. Otherwise, fetches
  /// assets and favorites from the server.
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

  /// Loads all financial assets for all market tabs.
  ///
  /// Fetches assets for Shares, Cryptos, and Forex groups and extracts
  /// current prices from the asset data.
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


  /// Loads user's favorite tickers from the server.
  ///
  /// Updates the internal favorites set and currency preference.
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

  /// Shows a dialog with detailed information about a financial asset.
  ///
  /// Displays asset name, ticker, type, country, and icon in a modal dialog.
  ///
  /// [context] The build context for showing the dialog.
  /// [a] The financial asset to display details for.
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

  /// Checks if a ticker is in the user's favorites.
  ///
  /// [ticker] The ticker symbol to check.
  /// Returns `true` if the ticker is favorited, `false` otherwise.
  bool isFavorite(String ticker) {
    return _favTickers.contains(ticker);
  }

  /// Toggles the favorite status of a ticker.
  ///
  /// Updates local state immediately and syncs with server. If sync fails,
  /// reverts the local change.
  ///
  /// [ticker] The ticker symbol to toggle.
  /// [onlyLocal] If `true`, only updates local state without server sync.
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

  /// Ordena la lista de activos según el criterio seleccionado (_sortOrder).
  List<FinancialAsset> _sortAssets(List<FinancialAsset> assets, int tabIndex) {
    final list = List<FinancialAsset>.from(assets);
    final maxOddsAll = MarketsView.getPreloadedMaxOdds();
    double maxOddFor(FinancialAsset a) {
      if (maxOddsAll == null) return 0.0;
      final mo = maxOddsAll[a.ticker] ?? maxOddsAll[a.ticker.toUpperCase()] ?? maxOddsAll[a.ticker.toLowerCase()];
      final o24 = mo?[24];
      return o24?.maxOdd ?? 0.0;
    }
    list.sort((a, b) {
      final aIsFav = _isFavTicker(a.ticker);
      final bIsFav = _isFavTicker(b.ticker);
      if (aIsFav && !bIsFav) return -1;
      if (!aIsFav && bIsFav) return 1;
      switch (_sortOrder) {
        case MarketsSortOrder.alphabet:
          return (a.name).toLowerCase().compareTo((b.name).toLowerCase());
        case MarketsSortOrder.value: {
          final aTicker = a.ticker.toUpperCase().trim();
          final bTicker = b.ticker.toUpperCase().trim();
          final aPrice = _assetPrices[aTicker] ?? MarketsView.getPreloadedPrices()?[aTicker];
          final bPrice = _assetPrices[bTicker] ?? MarketsView.getPreloadedPrices()?[bTicker];
          if (aPrice != null && bPrice != null) return bPrice.compareTo(aPrice);
          if (aPrice != null && bPrice == null) return -1;
          if (aPrice == null && bPrice != null) return 1;
          return 0;
        }
        case MarketsSortOrder.odd: {
          final oA = maxOddFor(a);
          final oB = maxOddFor(b);
          return oB.compareTo(oA);
        }
      }
    });
    return list;
  }

  Widget _buildLeafCardLayout(List<FinancialAsset> assets, int tabIndex) {
    if (!_scrollControllers.containsKey(tabIndex)) {
      _scrollControllers[tabIndex] = ScrollController();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (_) => false,
      child: CustomScrollView(
        controller: _scrollControllers[tabIndex],
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final asset = assets[index];
                  final isFav = _isFavTicker(asset.ticker);
                  Widget row = _buildMarketListRow(asset, index, tabIndex, isFav);
                  if (index == 0) {
                    _anyAssetRef = asset;
                    final key = tabIndex < _kAnyAssetByTab.length ? _kAnyAssetByTab[tabIndex] : null;
                    if (key != null) row = KeyedSubtree(key: key, child: row);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: row,
                  );
                },
                childCount: assets.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  /// Fila de lista: icono + nombre + precio y %. Si no hay precio, se carga desde velas.
  Widget _buildMarketListRow(FinancialAsset asset, int index, int tabIndex, bool isFav) {
    final tickerKey = asset.ticker.toUpperCase().trim();
    final price = asset.current ?? _assetPrices[tickerKey] ?? MarketsView.getPreloadedPrices()?[tickerKey];
    double? dailyGain = asset.dailyGain ?? MarketsView.getPreloadedDailyGains()?[tickerKey];
    if (dailyGain == null && price != null) {
      final prev = asset.close ?? MarketsView.getPreloadedPreviousPrices()?[tickerKey];
      if (prev != null && prev > 0) dailyGain = ((price - prev) / prev) * 100;
    }
    final maxOddsAll = MarketsView.getPreloadedMaxOdds();
    final maxOddsForTicker = maxOddsAll == null
        ? null
        : (maxOddsAll[asset.ticker] ?? maxOddsAll[asset.ticker.toUpperCase()] ?? maxOddsAll[asset.ticker.toLowerCase()]);
    return _MarketListRow(
      key: ValueKey(asset.ticker),
      asset: asset,
      isFav: isFav,
      initialPrice: price,
      initialDailyGain: dailyGain,
      initialClose: asset.close ?? MarketsView.getPreloadedPreviousPrices()?[tickerKey],
      dollarCurrency: _dollarCurrency,
      assetFallbackBadge: _assetFallbackBadge,
      onTap: () => _openAssetChart(asset),
      onLongPress: () => _showMarketRowBottomSheet(asset, isFav),
      maxOddsByTimeframe: maxOddsForTicker,
    );
  }

  void _showMarketRowBottomSheet(FinancialAsset asset, bool isFav) {
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
                leading: Icon(isFav ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star, color: Colors.white70),
                title: Text(
                  (isFav
                      ? LocalizedStrings.of(context)!.get('removeFromFavorites')!
                      : LocalizedStrings.of(context)!.get('addToFavorites')!),
                  style: GoogleFonts.montserrat(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  toggleFavorite(asset.ticker);
                },
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.crosshairs),
                title: Text(
                  LocalizedStrings.of(context)!.get('exactPriceBets') ?? "Exact price bets",
                  style: GoogleFonts.montserrat(),
                ),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  List<Candle> candles = await BetsService().fetchCandles(
                    asset.ticker,
                    1,
                    _dollarCurrency ? 'USD' : 'EUR',
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => ExactPricePage(
                        name: asset.name,
                        ticker: asset.ticker,
                        currentValue: candles.first.close,
                        iconPath: asset.icon,
                        isForex: Common().isTickerForex(asset.ticker),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(
                  LocalizedStrings.of(context)!.get('viewDetails') ?? "View details",
                  style: GoogleFonts.montserrat(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAssetDetails(context, asset);
                },
              ),
            ],
          ),
        );
      },
    );
  }



  /// Navega al primer elemento de la lista y abre su grafico.
  void _navigateToFirstAndOpen(int tabIndex) {
    final controller = _scrollControllers[tabIndex];
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final assets = assetsPerTab[tabIndex] ?? [];
      if (assets.isNotEmpty) {
        final firstAsset = assets.first;
        _openAssetChart(firstAsset, tutorialMode: true);
      }
    });
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final currentTab = _tabController.index;
        final assets = assetsPerTab[currentTab] ?? [];
        if (assets.isNotEmpty) {
          _anyAssetRef = assets.first;
        }
        if (mounted) {
          setState(() {});
        }
      }
    });

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
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
    try {
      _coach?.finish();
    } catch (_) {}
    _coach = null;
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

  Widget _buildSortSelector() {
    final strings = LocalizedStrings.of(context);
    final labels = {
      MarketsSortOrder.alphabet: strings?.get('sortByAlphabet') ?? 'Alfabeto',
      MarketsSortOrder.value: strings?.get('sortByValue') ?? 'Precio',
      MarketsSortOrder.odd: strings?.get('sortByOdd') ?? 'Cuota',
    };
    final selectedLabel = labels[_sortOrder]!;
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
        child: PopupMenuButton<MarketsSortOrder>(
          offset: const Offset(0, 40),
          color: Colors.grey.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (MarketsSortOrder order) {
            setState(() => _sortOrder = order);
          },
          itemBuilder: (BuildContext context) => MarketsSortOrder.values.map((order) {
            final isSelected = _sortOrder == order;
            return PopupMenuItem<MarketsSortOrder>(
              value: order,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    labels[order]!,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Icon(FontAwesomeIcons.check, size: 16, color: Colors.purple.shade200),
                    ),
                ],
              ),
            );
          }).toList(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  FontAwesomeIcons.arrowUpShortWide,
                  size: 20,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedLabel,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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
                    final raw = assetsPerTab[index] ?? [];
                    final assets = _sortAssets(raw, index);
                    return _buildLeafCardLayout(assets, index);
                  }),
                ),
        ),
        if (!_isLoading) _buildSortSelector(),
      ],
    );
  }

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
      final tabIndex = _tabController.index;
      final anyKey = tabIndex < _kAnyAssetByTab.length ? _kAnyAssetByTab[tabIndex] : null;
      final ready = _kTabs.currentContext != null && (anyKey?.currentContext != null);
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
        keyTarget: _kAnyAssetByTab[_tabController.index.clamp(0, _kAnyAssetByTab.length - 1)],
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
    final currentTab = _tabController.index;
    final assets = assetsPerTab[currentTab] ?? [];
    if (assets.isNotEmpty) {
      _anyAssetRef = assets.first;
    }
    if (mounted) {
      setState(() {});
    }
    await Future.delayed(const Duration(milliseconds: 200));
    final controller = _scrollControllers[currentTab];
    if (controller != null && controller.hasClients) {
      controller.jumpTo(0.0);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    await _waitForTargetsReady();
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
            Future.delayed(const Duration(milliseconds: 200), () {
              if (!mounted) return;
              try {
                _coach?.finish();
              } catch (e) {
                if (kDebugMode) {
                  print("TutorialCoachMark error ${e.toString()}");
                }
              }
            });
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted && _anyAssetRef != null) {
                final currentTab = _tabController.index;
                _navigateToFirstAndOpen(currentTab);
              }
            });
          }
        } catch (_) {}
      },
      onClickOverlay: (target) async {
        try {
          if (target.identify == 'mv_tabs') {
            final currentTab = _tabController.index;
            final controller = _scrollControllers[currentTab];
            if (controller != null && controller.hasClients) {
              controller.jumpTo(0.0);
              await Future.delayed(const Duration(milliseconds: 200));
              final ki = _tabController.index.clamp(0, _kAnyAssetByTab.length - 1);
              if (mounted && _kAnyAssetByTab[ki].currentContext == null) {
                for (int i = 0; i < 10; i++) {
                  await Future.delayed(const Duration(milliseconds: 50));
                  if (_kAnyAssetByTab[ki].currentContext != null) break;
                }
              }
            }
          }
        } catch (_) {}
      },
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
    if (!mounted) return;
    _coach!.show(context: context);
  }
}

/// Fila de lista con carga asíncrona de precio cuando no viene del API.
class _MarketListRow extends StatefulWidget {
  final FinancialAsset asset;
  final bool isFav;
  final double? initialPrice;
  final double? initialDailyGain;
  final double? initialClose;
  final bool dollarCurrency;
  final Widget Function(FinancialAsset, double) assetFallbackBadge;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  /// Max odds por timeframe (1, 2, 4, 24) para este ticker; si null se usan valores por defecto.
  final Map<int, ({double maxOdd, int direction, int zoneId})>? maxOddsByTimeframe;

  const _MarketListRow({
    super.key,
    required this.asset,
    required this.isFav,
    this.initialPrice,
    this.initialDailyGain,
    this.initialClose,
    required this.dollarCurrency,
    required this.assetFallbackBadge,
    required this.onTap,
    required this.onLongPress,
    this.maxOddsByTimeframe,
  });

  @override
  State<_MarketListRow> createState() => _MarketListRowState();
}

class _MarketListRowState extends State<_MarketListRow> {
  double? _loadedPrice;
  double? _loadedDailyGain;
  bool _loading = false;

  double? get _price => _loadedPrice ?? widget.initialPrice;
  double? get _dailyGain => _loadedDailyGain ?? widget.initialDailyGain;

  @override
  void initState() {
    super.initState();
    if (_price == null) { _loadPrice(); }
    else if (_dailyGain == null && _price != null && (widget.initialClose != null && widget.initialClose! > 0)) {
      setState(() {
        _loadedDailyGain = ((_price! - widget.initialClose!) / widget.initialClose!) * 100;
      });
    }
  }

  Future<void> _loadPrice() async {
    if (_loading) return;
    _loading = true;
    try {
      final currency = widget.dollarCurrency ? 'USD' : 'EUR';
      final candles = await BetsService().fetchCandles(widget.asset.ticker, 1, currency);
      if (!mounted) return;
      if (candles.isNotEmpty) {
        final current = candles.first.close;
        double? gain;
        if (candles.length > 1 && candles[1].close > 0) {
          gain = ((current - candles[1].close) / candles[1].close) * 100;
        }
        setState(() {
          _loadedPrice = current;
          _loadedDailyGain = gain;
        });
      }
    } finally {
      if (mounted) _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = _price;
    final dailyGain = _dailyGain;
    final isForex = Common().isTickerForex(widget.asset.ticker);
    final currency = isForex ? '' : (widget.dollarCurrency ? '\$' : '€');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isFav
                ? Colors.amber.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isFav ? Colors.amber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          clipBehavior: Clip.none,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.asset.icon.isNotEmpty &&
                        widget.asset.icon != "null" &&
                        !widget.asset.icon.contains("http")
                    ? Image.memory(
                        base64Decode(widget.asset.icon),
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => widget.assetFallbackBadge(widget.asset, 48),
                      )
                    : widget.asset.icon.isNotEmpty && widget.asset.icon.contains("http")
                        ? Image.network(
                            widget.asset.icon,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => widget.assetFallbackBadge(widget.asset, 48),
                          )
                        : widget.assetFallbackBadge(widget.asset, 48),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.asset.name.split(' ').take(2).join(' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.syncopate(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (_loading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                          )
                        else
                          Text(
                            price != null && price > 0
                                ? '${price > 1 ? price.toStringAsFixed(2) : price.toStringAsFixed(4)}$currency'
                                : currency,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: price != null && price > 0 ? Colors.white : Colors.white54,
                            ),
                          ),
                        const SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (dailyGain != null)
                              Icon(
                                dailyGain >= 0 ? FontAwesomeIcons.arrowTrendUp : FontAwesomeIcons.arrowTrendDown,
                                size: 14,
                                color: dailyGain >= 0 ? const Color(0xFF00C853) : const Color(0xFFDC2626),
                              ),
                            if (dailyGain != null) const SizedBox(width: 4),
                            Text(
                              dailyGain != null
                                  ? '${dailyGain.toStringAsFixed(2)}%'
                                  : '—',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: dailyGain != null
                                    ? (dailyGain >= 0 ? const Color(0xFF00C853) : const Color(0xFFDC2626))
                                    : Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                  Expanded(
                    flex: 2,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final mo = widget.maxOddsByTimeframe;
                        final o24 = mo?[24] ?? (maxOdd: 1.0, direction: 0, zoneId: 0);
                        final o4 = mo?[4] ?? (maxOdd: 1.0, direction: 0, zoneId: 0);
                        final o1 = mo?[1] ?? (maxOdd: 1.0, direction: 0, zoneId: 0);
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _MarketsOddZone(maxOdd: o24.maxOdd, direction: o24.direction, currentPrice: _price ?? 0.0, timeframeHours: 24),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _MarketsOddZone(maxOdd: o4.maxOdd, direction: o4.direction, currentPrice: _price ?? 0.0, timeframeHours: 4),
                                  const SizedBox(width: 14),
                                  _MarketsOddZone(maxOdd: o1.maxOdd, direction: o1.direction, currentPrice: _price ?? 0.0, timeframeHours: 1),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (widget.isFav)
                Positioned(
                  top: -6,
                  left: -6,
                  child: Icon(FontAwesomeIcons.solidStar, size: 22, color: Colors.amber.shade300),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zona de odds para la fila de mercados: copia local más grande (no reutiliza trends.dart).
class _MarketsOddZone extends StatelessWidget {
  final double maxOdd;
  final int direction; // +1 verde, 0 amarillo, -1 rojo
  final double currentPrice;
  /// Timeframe en horas: 1, 2, 4 o 24 (se muestra "Xh" en la esquina superior izquierda).
  final int timeframeHours;

  const _MarketsOddZone({
    required this.maxOdd,
    required this.direction,
    required this.currentPrice,
    this.timeframeHours = 1,
  });

  Color _fillColor() {
    if (direction == 1) return Colors.green.withValues(alpha: 1);
    if (direction == -1) return Colors.red.withValues(alpha: 1);
    return Colors.orange.withValues(alpha: 1);
  }

  @override
  Widget build(BuildContext context) {
    const double w = 155;
    const double h = 90;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(w, h),
            painter: _MarketsOddZonePainter(maxOdd: maxOdd, fillColor: _fillColor()),
          ),
          Positioned(
            top: -4,
            left: -15,
            child: Text(
              '${timeframeHours.clamp(1, 24)}H',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketsOddZonePainter extends CustomPainter {
  final double maxOdd;
  final Color fillColor;

  _MarketsOddZonePainter({required this.maxOdd, required this.fillColor});

  @override
  bool shouldRepaint(covariant _MarketsOddZonePainter oldDelegate) =>
      oldDelegate.maxOdd != maxOdd || oldDelegate.fillColor != fillColor;

  Color oddsToColor(double odds, Color fillColor) {
    const double minOdds = 1.0, maxOdds = 6.0;
    final double clamped = odds.clamp(minOdds, maxOdds).toDouble();
    const double minAlpha = 0.65, maxAlpha = 0.85;
    final double t = (clamped - minOdds) / (maxOdds - minOdds);
    return fillColor.withValues(alpha: minAlpha + (maxAlpha - minAlpha) * t);
  }

  Shader buildZoneShader(Color base, double odds, Rect rect) {
    const double minOdds = 1.0, maxOdds = 6.0;
    final double t = ((odds.clamp(minOdds, maxOdds) - minOdds) / (maxOdds - minOdds)).toDouble();
    final hsl = HSLColor.fromColor(base);
    final double baseLight = hsl.lightness;
    final double darkFactor = lerpDouble(0.65, 0.8, t)!;
    final double lightFactor = lerpDouble(1.02, 1.15, t)!;
    const double transparencyFactor = 0.92;
    final Color startColor = hsl
        .withLightness((baseLight * darkFactor).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: transparencyFactor);
    final Color endColor = hsl
        .withLightness((baseLight * lightFactor).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: transparencyFactor);
    return LinearGradient(
      colors: [startColor, endColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(rect);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const rrectRadius = Radius.circular(45);
    final RRect rrect = RRect.fromRectAndRadius(rect, rrectRadius);

    // Mismo estilo de flotación que los RectangleZones del gráfico de candlesticks (RangePainter)
    const double minOdds = 1.0, maxOdds = 6.0;
    final double clampedOdds = maxOdd.clamp(minOdds, maxOdds).toDouble();
    final double elevationFactor = (clampedOdds - minOdds) / (maxOdds - minOdds);
    final double shadowOffset = 3.0 + (elevationFactor * 7.0);
    final RRect shadowRrect = RRect.fromRectAndRadius(
      rect.shift(Offset(shadowOffset, shadowOffset)),
      rrectRadius,
    );
    final double shadowAlpha1 = 0.25 + (elevationFactor * 0.25);
    final double shadowAlpha2 = 0.3 + (elevationFactor * 0.3);
    final double blurRadius1 = 6.0 + (elevationFactor * 6.0);
    final double blurRadius2 = 3.0 + (elevationFactor * 4.0);

    final paintShadow1 = Paint()
      ..isAntiAlias = true
      ..color = Colors.black.withValues(alpha: shadowAlpha1)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius1)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(shadowRrect, paintShadow1);
    final paintShadow2 = Paint()
      ..isAntiAlias = true
      ..color = Colors.black.withValues(alpha: shadowAlpha2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius2)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(shadowRrect, paintShadow2);

    final paintFill = Paint()
      ..isAntiAlias = true
      ..shader = buildZoneShader(fillColor, maxOdd, rect)
      ..color = oddsToColor(maxOdd, fillColor)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paintFill);

    final paintBorder = Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(rrect, paintBorder);

    const double fontSize = 35.0;
    final oddsTextSpan = TextSpan(
      text: 'x${maxOdd.toStringAsFixed(2)}',
      style: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
      ),
    );
    final textPainter = TextPainter(text: oddsTextSpan, textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    final textX = (size.width - textPainter.width) / 2;
    final textY = (size.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textX, textY));
  }
}

//------ Helpers como extension de MarketsViewState
extension _MarketsViewStateExtension on MarketsViewState {
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
}
//------ ARC SELECTOR WIDGET

/// A widget that displays financial assets in an arc selector interface.
///
/// Supports drag gestures for scrolling through assets with inertia,
/// displays up to 5 visible items at a time, and provides tap/long-press
/// callbacks for asset interactions.
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
  
  static const double _rotationSensitivity = 0.02; // Sensibilidad de rotacion
  static const double _friction = 0.92; // Friccion para inercia
  static const double _minVelocity = 0.5; // Velocidad minima para continuar
  static const int _visibleItems = 5; // Numero de elementos visibles a la vez
  
  // Indice base que representa el elemento central
  double _baseIndex = 0.0; // Usamos double para permitir valores fraccionarios durante animacion

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
      // Convertir desplazamiento horizontal a cambio de Indice
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
    
    // Snap al Indice mas cercano
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

  // Determinar que elementos estan visibles
  List<int> _getVisibleIndices() {
    if (widget.assets.isEmpty) return [];
    
    final centerOffset = (_visibleItems - 1) / 2;
    final baseIndexInt = _baseIndex.round();
    
    // Obtener Índices visibles alrededor del base (2 antes, base, 2 despues = 5 total)
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
    
    // Parametros del arco
    final centerX = size.width / 2;
    final centerY = size.height * 0.35;
    final radius = math.min(size.width, size.height) * 0.38;
    
    // Arco semicircular de 180 grados
    final startAngle = -math.pi / 2; // -90 grados (arriba)
    final arcAngle = math.pi; // 180 grados
    final anglePerItem = arcAngle / (_visibleItems - 1);
    final centerOffset = (_visibleItems - 1) / 2.0;
    
    // Calcular posicion relativa del elemento en el arco visible
    final relativePosition = positionInVisible - centerOffset;
    
    // Calcular el offset fraccional desde el Índice base
    final fractionalOffset = _baseIndex - _baseIndex.round();
    
    // Angulo del elemento ajustado por el offset fraccional
    final adjustedPosition = relativePosition - fractionalOffset;
    final itemAngle = startAngle + (centerOffset * anglePerItem) + (adjustedPosition * anglePerItem);
    
    // Normalizar al rango [0, 2Ï€]
    final normalizedAngle = (itemAngle % (math.pi * 2) + (math.pi * 2)) % (math.pi * 2);
    
    // Calcular posicion en el arco
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
        
        // Obtener solo los Índices visibles
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
    // Opcional: dibujar guÍa del arco si se necesita
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height * 0.3);
    final radius = math.min(size.width, size.height) * 0.32;
    
    // Dibujar arco guÍa (semicÍrculo superior)
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
