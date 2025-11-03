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
  Timer? _clockTimer;
  Timer? _refreshTimer;

  void _refreshData() async {
    final userId = await _storage.read(key: "sessionToken") ?? "none";
    final userPoints = await _storage.read(key: "points") ?? "0";

    if (!mounted) return;

    setState(() {
      _userId = userId != "none" ? userId : null;
      _userPoints = double.tryParse(userPoints) ?? 0;
      _trendsFuture = BetsService().fetchTrendsData(_userId ?? "none");
      _favsFuture = BetsService().fetchFavouritesData(_userId ?? "none");
    });
  }

  Future<void> loadUserIdAndData() async {
    final userId = await _storage.read(key: "sessionToken") ?? "none";
    final userPoints = await _storage.read(key: "points") ?? "0";

    setState(() {
      _userId = userId != "none" ? userId : null;
      _userPoints = double.tryParse(userPoints) ?? 0;
      _trendsFuture = BetsService().fetchTrendsData(_userId ?? "none");
      _favsFuture   = BetsService().fetchFavouritesData(_userId ?? "none");
      _investmentFuture = BetsService().fetchInvestmentData(_userId ?? "none"); // ← una vez
    });

    _investmentFuture!.then((data) {
      if (!mounted) return;
      setState(() {
        _bets = List.from(data.bets.investList);
        _priceBets = List.from(data.priceBets);
        _investInited = true;
      });
    });
  }

  void refreshFavorites() {
    setState(() {
      _favsFuture = BetsService().fetchFavouritesData(_userId ?? "none");
    });
  }

  Future<void> refreshInvestments() async {
    if (!mounted || _userId == null) return;
    try {
      final data = await BetsService().fetchInvestmentData(_userId!);
      if (!mounted) return;
      setState(() {
        _bets      = List.from(data.bets.investList);
        _priceBets = List.from(data.priceBets);
      });
    } catch (_) { }
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _delayedAutoScrollInit();
    });
    loadUserIdAndData().then((_) {
      setState(() {
        _trendsFuture = BetsService().fetchTrendsData(_userId ?? "none");
        _favsFuture = BetsService().fetchFavouritesData(_userId ?? "none");
      });
    });

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      _refreshData();
      await refreshInvestments();

    });
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
            // Upper icons
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                  icon: Icon(FontAwesomeIcons.gear),
                  iconSize: 25,
                  color: Colors.white70,
                  onPressed: () {
                    Common().vibrate();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsView(
                          onPersonalInfoTap: () {
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
                        ),
                      ),
                    );
                  },
                ),
                Spacer(flex: 5),
                Text(
                  "betrader.v1",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syncopate(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                Spacer(flex: 4),
                IconButton(
                    padding: const EdgeInsets.all(2.5),
                    onPressed: () async {
                      Common().vibrate();
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
                              ]),
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
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white),
                                ),
                              ],
                            ))))
              ],
            ),

            // Trends
            Text(strings?.get('liveBets') ?? 'Trends',
                style: GoogleFonts.syncopate(
                  fontSize: 18,
                  fontWeight: FontWeight.w200,
                )),
            Divider(color: Colors.white, thickness: 0.5, height: 0.5),
            Expanded(
              flex: 9,
              child: _userId == null
                  ? Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
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
                  : Expanded(
                      flex: 9,
                      child: FutureBuilder<Trends>(
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
                                  final sortedTrends = List.from(data.trends)
                                    ..sort((a, b) => a.id.compareTo(b.id));
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
            ),

            // Favorites
            Row(
              children: [
                Text(strings?.get('favs') ?? 'Favs',
                    style: GoogleFonts.syncopate(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    )),
              ],
            ),
            Divider(color: Colors.white, thickness: 0.5, height: 0.5),
            Expanded(
              flex: 8,
              child: _userId == null
                  ? Center(
                      child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
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
                    ))
                  : FutureBuilder<Favorites>(
                      future: _favsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    SizedBox(width: 8),
                                    SkeletonFavoriteContainer(),
                                    SizedBox(width: 8),
                                    SkeletonFavoriteContainer(),
                                    SizedBox(width: 8),
                                    SkeletonFavoriteContainer(),
                                    SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (snapshot.hasData &&
                            snapshot.data!.favorites.isNotEmpty) {
                          final data = snapshot.data!;
                          return ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              overscroll: false,
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(
                                  decelerationRate:
                                      ScrollDecelerationRate.fast),
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
                                    LocalizedStrings.of(context)!
                                            .get('noFavsYet') ??
                                        "No favorites yet!",
                                    style: GoogleFonts.dosis(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Icon(
                                    Icons.star_border,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }),
            ),

            // Recent bets
            Row(
              children: [
                Text(
                  strings?.get('recentBets') ?? 'Recent Bets',
                  style: GoogleFonts.syncopate(
                      fontSize: 16, fontWeight: FontWeight.w200),
                ),
                Spacer(),
                const HourCountdown(),
              ],
            ),
            Divider(color: Colors.white, thickness: 0.5, height: 0.5),
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
                      snapshot.connectionState == ConnectionState.waiting) {
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
                                LocalizedStrings.of(context)!
                                    .get('noLiveBets') ??
                                    'You have no live bets at the moment, go to the markets tab to create a new one',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Image.asset('assets/new_icon.png'),
                                  ),
                                  const SizedBox(width: 5.0),
                                  const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      floatingActionButton: FloatingActionButton(
                          backgroundColor: Colors.transparent.withValues(alpha: 0.1),
                          splashColor: Colors.grey,
                          onPressed: () {
                            Common().vibrate();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BetsHistoryPage(),
                              ),
                            );
                          },
                          child: const Icon(FontAwesomeIcons.clockRotateLeft, color: Colors.white),
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
                            bottom: MediaQuery.of(context).padding.bottom + 50,
                          ),
                          children: [
                            // Bets
                            ..._bets.reversed.map(
                                  (b) => RecentBetContainer(
                                necessaryGain: b.necessaryGain,
                                bet: b,
                                onDelete: () => setState(() {
                                  _bets.removeWhere((x) => x.id == b.id);
                                }),
                                controller: widget.controller,
                              ),
                            ),
                            // Price Bets
                            ..._priceBets.reversed.map(
                                  (p) => RecentPriceBetContainer(
                                priceBet: p,
                                onDelete: () => setState(() {
                                  _priceBets.removeWhere((x) => x.id == p.id);
                                }),
                                controller: widget.controller,
                                isForex: Common().isTickerForex(p.ticker),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    floatingActionButton: Transform.translate(
                        offset: const Offset(14, 14),
                        child: FloatingActionButton(
                          backgroundColor: Colors.transparent.withValues(alpha: 0.1),
                          splashColor: Colors.grey,
                          onPressed: () {
                            Common().vibrate();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BetsHistoryPage(),
                              ),
                            );
                          },
                          child: const Icon(FontAwesomeIcons.clockRotateLeft, color: Colors.white),
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
    );
  }

  @override
  void dispose() {
    _trendScrollController.dispose();
    _ticker?.dispose;
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }
}

class HourCountdown extends StatefulWidget {
  const HourCountdown({super.key});

  @override
  State<HourCountdown> createState() => _HourCountdownState();
}

class _HourCountdownState extends State<HourCountdown> {
  late Timer _timer;
  late String formattedDate;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final remaining = nextHour.difference(now);

    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    setState(() {
      formattedDate = '$minutes:${seconds.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(FontAwesomeIcons.rotateRight,
            color: Colors.white70, size: 10),
        const Icon(FontAwesomeIcons.hourglassHalf,
            color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          formattedDate,
          textAlign: TextAlign.right,
          style: GoogleFonts.syncopate(
            fontSize: 14,
            fontWeight: FontWeight.w200,
            color: Colors.white,
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
