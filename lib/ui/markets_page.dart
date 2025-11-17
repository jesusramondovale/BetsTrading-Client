import 'dart:convert';
import 'dart:ui';
import 'package:betrader/services/AssetsService.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../Services/BetsService.dart';
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
}

class MarketsViewState extends State<MarketsView> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final _kTabs = GlobalKey();
  final _kAnyAsset = GlobalKey();
  FinancialAsset? _anyAssetRef;
  List<String> groups = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<int, List<FinancialAsset>> assetsPerTab = {};
  bool _isLoading = true;
  Set<String> _favTickers = {};
  bool _isFavTicker(String t) => _favTickers.contains(t.toUpperCase().trim());
  static const  _PENDING_FLAG = '__tutorial_pending__markets_v1';
  static const _SEEN_FLAG = '__tutorial_seen__markets_v1';
  TutorialCoachMark? _coach;
  late final VoidCallback _tabListener;

  void _initGroups() {
    final strings = LocalizedStrings.of(context);
    groups = [
      strings?.get('shares') ?? 'Shares',
      'Crypto',
      'Forex',
    ];
  }

  Future<void> _loadData() async {
    await _loadAllAssets();
    await _loadFavorites();
    setState(() => _isLoading = false);
  }

  Future<void> _loadAllAssets() async {
    Map<int, String> groupMapping = {
      0: 'Shares',
      1: 'Cryptos',
      2: 'Forex',
    };

    for (int id = 0; id < groups.length; id++) {
      String? theGroup = groupMapping[id];
      if (theGroup != null) {
        final newAssets =
        await AssetsService().getFinancialAssetsByGroup(theGroup);
        assetsPerTab[id] = newAssets ?? [];
      }
    }
  }

  Future<void> _loadFavorites() async {
    final token = await _storage.read(key: "sessionToken") ?? "";
    final Favorites favs = await BetsService().fetchFavouritesData(token);
    final tickers = favs.favorites
        .map((f) => f.ticker.toUpperCase().trim())
        .where((t) => t.isNotEmpty)
        .toSet();
    setState(() {
      _favTickers = tickers;
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
      await _loadFavorites();
    }

    homeScreenKey.currentState?.refreshFavorites();
  }

  Widget _buildFavBadge() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.all(3),
        child: Icon(FontAwesomeIcons.solidStar, size: 25, color: Colors.white70.withValues(alpha: 0.7)),
      ),
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
    _initGroups();
    _loadData();
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
          child:  _isLoading
                ? GridView.builder(
              padding: const EdgeInsets.all(6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 5.0,
                mainAxisSpacing: 7.0,
                childAspectRatio: 1.0,
              ),
              itemCount: 15,
              itemBuilder: (_, __) => const SkeletonAssetContainer(),
            )
                : TabBarView(
              controller: _tabController,
              children: List.generate(groups.length, (index) {
                final List<FinancialAsset> assets = assetsPerTab[index] ?? [];

                assets.sort((a, b) {
                  final af = _isFavTicker(a.ticker);
                  final bf = _isFavTicker(b.ticker);
                  if (af != bf) return af ? -1 : 1;
                  final byName = a.name.compareTo(b.name);
                  if (byName != 0) return byName;
                  return a.ticker.compareTo(b.ticker);
                });

                return GridView.builder(
                  padding: const EdgeInsets.all(6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 5.0,
                    mainAxisSpacing: 7.0,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: assets.length,
                  itemBuilder: (context, assetIndex) {
                    final asset = assets[assetIndex];
                    final isFav = _favTickers.contains(asset.ticker.toUpperCase().trim());

                    Widget tile = Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Stack(
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
                              onTap: () {
                                _openAssetChart(asset);
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
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: Icon(
                                            isFav ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
                                            color: Colors.white70,
                                          ),
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
                                            List<Candle> candles = await BetsService().fetchCandles(asset.ticker,1);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ExactPricePage(
                                                  name: asset.name,
                                                  ticker: asset.ticker,
                                                  currentValue: candles.first.close,
                                                  iconPath: asset.icon,
                                                  isForex: asset.group.toLowerCase() == "forex",
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        ListTile(
                                            leading: const Icon(Icons.notifications_none),
                                            title: Text(
                                              LocalizedStrings.of(context)!.get('createAlert') ?? "Create alert",
                                              style: GoogleFonts.montserrat(),
                                            ),
                                            onTap: () {
                                              Common().showFloatingSnack(context, "Unimplemented action!" , backgroundColor: Colors.black54);
                                              Navigator.pop(context);

                                            }
                                        ),
                                        ListTile(
                                            leading: const Icon(Icons.info_outline),
                                            title: Text(
                                                LocalizedStrings.of(context)!.get('viewDetails') ?? "View details",
                                                style: GoogleFonts.montserrat()),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _showAssetDetails(context, asset);
                                            }
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
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
                              //TODO
                              top: -7,
                              left: -10,
                              child: _buildFavBadge(),
                            ),
                        ],
                      ),
                    );

                    if (assetIndex == 0 && _kAnyAsset.currentContext == null) {
                      _anyAssetRef ??= asset;
                      tile = KeyedSubtree(key: _kAnyAsset, child: tile);
                    }

                    return tile;

                  },
                );
              }),

            )
          ,
        ),
      ],
    );
  }

  //------ T U T O R I A L      M E T H O D S -----
  Future<void> _markSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_SEEN_FLAG, true);
  }

  Future<void> _clearPending() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_PENDING_FLAG);
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
                    'Switch between different markets: Shares, Crypto, and Forex. Tabs are scrollable and remember your last selection. Favorites appear first in each category, and data refreshes automatically during the session.'
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
    final pending = prefs.getBool(_PENDING_FLAG) ?? false;
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
          child: Container(
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
