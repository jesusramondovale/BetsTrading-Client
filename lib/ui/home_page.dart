import 'dart:async';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/models/favorites.dart';
import 'package:betrader/services/BetsService.dart';
import 'package:betrader/ui/betshistory_page.dart';
import 'package:betrader/ui/settings_view.dart';
import 'package:betrader/ui/store_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../helpers/common.dart';
import '../models/bets.dart';
import '../models/trends.dart';
import 'layout_page.dart';
import 'notifications_page.dart';

class HomeScreen extends StatefulWidget {
  final MainMenuPageController controller;
  const HomeScreen({super.key, required this.controller});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
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
  bool _userIsInteracting = false;
  final ScrollController _trendScrollController = ScrollController();
  Ticker? _ticker;
  double _direction = 1;
  Timer? _refreshTimer;
  final GlobalKey _kSettings = GlobalKey();
  final GlobalKey _kStore = GlobalKey();
  final GlobalKey _kTrends = GlobalKey();
  final GlobalKey _kFavorites = GlobalKey();
  final GlobalKey _kBets = GlobalKey();
  final GlobalKey _kHistory = GlobalKey();
  TutorialCoachMark? _coach;
  bool _dollarCurrency = false;

  void _refreshData() async {
    final userId = await _storage.read(key: "sessionToken") ?? "none";
    await BetsService().getUserInfo(userId);
    final userPoints = await _storage.read(key: "points") ?? "0";
    final prefs = await SharedPreferences.getInstance();
    final dollarCurrency = prefs.getBool('dollarCurrency') ?? false;

    if (!mounted) return;

    setState(() {
      _userId = userId != "none" ? userId : null;
      _userPoints = double.tryParse(userPoints) ?? 0;
      _dollarCurrency = dollarCurrency;
      _trendsFuture = BetsService()
          .fetchTrendsData(_userId ?? "none", _dollarCurrency ? 'USD' : 'EUR');
      _favsFuture = BetsService()
          .fetchFavouritesData(_userId ?? "none", _dollarCurrency ? 'USD' : 'EUR');
    });
  }

  Future<void> loadUserIdAndData() async {
    final userId = await _storage.read(key: "sessionToken") ?? "none";
    final userPoints = await _storage.read(key: "points") ?? "0";
    final prefs = await SharedPreferences.getInstance();
    final dollarCurrency = prefs.getBool('dollarCurrency') ?? false;

    if (!mounted) return;

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

  void refreshFavorites() {
    setState(() {
      _favsFuture = BetsService()
          .fetchFavouritesData(_userId ?? "none", _dollarCurrency ? 'USD' : 'EUR');
    });
  }

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

  void _delayedAutoScrollInit() async {
    await Future.delayed(const Duration(seconds: 3));
    _startAutoScroll();
  }

  void _startAutoScroll() {
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
    });

    _ticker!.start();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _delayedAutoScrollInit();

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

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      _refreshData();
      await refreshInvestments();
    });
  }

  Future<bool> _hasSeen(String key) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('__tutorial_seen__$key') ?? false;
  }

  Future<void> _markSeen(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('__tutorial_seen__$key', true);
  }

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
        return true;
      },
      onFinish: () async {
        await _markSeen('home_onboarding_v1');
        final p = await SharedPreferences.getInstance();
        await p.setBool('__tutorial_pending__awards_v1', true);

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
                  onPressed: () async {
                    Common().vibrate();
                    Common().applyImmersive();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StorePage()),
                    );
                    exchangePageKey.currentState?.loadData();
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
                      child: Row(
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
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
                            return Text('Error: ${snapshot.error}');
                          } else if (snapshot.hasData &&
                              snapshot.data!.trends.isNotEmpty) {
                            final data = snapshot.data!;
                            return Listener(
                              onPointerDown: (_) {
                                _userIsInteracting = true;
                                Common().applyImmersive();
                              },
                              onPointerUp: (_) async {
                                await Future.delayed(
                                    const Duration(seconds: 2));
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
                            );
                          } else {
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
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
                            );
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (snapshot.hasData &&
                              snapshot.data!.favorites.isNotEmpty) {
                            final data = snapshot.data!;
                            return ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context)
                                  .copyWith(overscroll: false),
                              child: ListView.builder(
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
    _trendScrollController.dispose();
    _ticker?.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
