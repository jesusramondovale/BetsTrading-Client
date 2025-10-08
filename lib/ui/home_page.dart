import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/models/favorites.dart';
import 'package:betrader/services/BetsService.dart';
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
  List<Bet> _bets = [];
  String? _userId;
  double _userPoints = 0;
  late Future<Trends> _trendsFuture;
  late Future<Favorites> _favsFuture;
  bool _userIsInteracting = false;
  final ScrollController _trendScrollController = ScrollController();
  Ticker? _ticker;
  double _direction = 1;
  Future<void> loadUserIdAndData() async {
    final userId = await _storage.read(key: "sessionToken") ?? "none";
    final userPoints = await _storage.read(key: "points") ?? "0";
    setState(() {
      _userId = userId != "none" ? userId : null;
      _userPoints = double.tryParse(userPoints) ?? 0;
    });
    _loadBets(userId);
  }

  Future<void> _loadBets(String userId) async {
    final betsData = await BetsService().fetchInvestmentData(userId);
    setState(() {
      _bets = betsData.bets.investList;
    });
  }

  void _deleteBet(int betId) {
    setState(() {
      _bets.removeWhere((bet) => bet.id == betId);
    });
  }

  void refreshFavorites() {
    setState(() {
      _favsFuture = BetsService().fetchFavouritesData(_userId ?? "none");
    });
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

  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    Locale locale = Localizations.localeOf(context);
    String formattedDate =
        DateFormat.yMMMMd(locale.toString()).format(DateTime.now());

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
                          ]
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
                      )
                    )
                  )
                )
              ],
            ),

            // Trends
            Row(
              children: <Widget>[
                Text(strings?.get('liveBets') ?? 'Trends',
                    style: GoogleFonts.comfortaa(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    )),
                const Spacer(),
                const SizedBox(width: 5),
                AutoSizeText(
                  formattedDate,
                  style: GoogleFonts.dosis(
                    fontSize: 18,
                    fontWeight: FontWeight.w200,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
            ),
            Divider(
                color: Colors.white,
                thickness: 0.5,
                height: 0.5),
            Expanded(
              flex: 9,
              child: _userId == null
                  ?  Center(
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
                  :
              Expanded(
                flex: 9,
                child: FutureBuilder<Trends>(
                  future: _trendsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
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
                    } else if (snapshot.hasData && snapshot.data!.trends.isNotEmpty) {
                      final data = snapshot.data!;

                      return Listener(
                        onPointerDown: (_) {
                          _userIsInteracting = true;
                        },
                        onPointerUp: (_) async {
                          await Future.delayed(const Duration(seconds: 2));
                          _userIsInteracting = false;
                        },
                          child: ListView.builder(
                          controller: _trendScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: data.trends.length,
                          itemBuilder: (context, index) {
                            final sortedTrends = List.from(data.trends)
                              ..sort((a, b) => a.id.compareTo(b.id));
                            final sortedIndex = sortedTrends[index].id - 1;

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

            Text(strings?.get('favs') ?? 'Favs',
                  style: GoogleFonts.comfortaa(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  )),
            Divider(
                color: Colors.white,
                thickness: 0.5,
                height: 0.5),
            Expanded(
              flex: 8,
              child: _userId == null
                  ? Center(child: Center(
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
                  :
              FutureBuilder<Favorites>(
                  future: _favsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return  Center(
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
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return FavoriteContainer(
                              favorite: data.favorites[index],
                              onFavoriteUpdated: refreshFavorites, controller: widget.controller,);
                        },
                      );
                    } else {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                LocalizedStrings.of(context)!.get('noFavsYet') ??
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
                  style: GoogleFonts.comfortaa(
                      fontSize: 20, fontWeight: FontWeight.w400),
                ),
                Spacer(),
                IconButton(icon: Icon(Icons.auto_delete), color: Colors.white70,
                    onPressed:  () async {
                        Common().vibrate();
                        bool result = await BetsService().deleteHistoricBets(_userId ?? "none");
                        if (result) {
                          Common().showFloatingSnack(context, LocalizedStrings.of(context)!.get('betsDeleted') ?? "Bets deleted");
                          setState(() {

                          });
                        }
                }
                ),
                IconButton(icon: Icon(FontAwesomeIcons.rotate),
                    color: Colors.white70,
                  onPressed: () async => {
                  Common().vibrate(),
                  await BetsService().getUserInfo(_userId ?? "none"),
                  loadUserIdAndData(),
                  setState(() {


                  })}
                )
              ],
            ),
            Divider(
                color: Colors.white,
                thickness: 0.5,
                height: 0.5),
            Expanded(
              flex: 12,
              child: _userId == null
                  ? ListView(children: const [
                        SkeletonRecentBetContainer(),
                        SkeletonRecentBetContainer(),
                  ],
                )
                  :
              FutureBuilder<BetsAndPriceBets>(
                future: BetsService().fetchInvestmentData(_userId ?? "none"),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView(
                      children: const [
                        SkeletonRecentBetContainer(),
                        SkeletonRecentBetContainer(),
                      ],
                    );
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final data = snapshot.data!;
                  final bets = data.bets.investList;
                  final priceBets = data.priceBets;

                  if (bets.isEmpty && priceBets.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              strings!.get('noLiveBets') ??
                                  'You have no live bets at the moment, go to the markets tab to create a new one',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              ),
                            ),
                            Row(
                              mainAxisAlignment : MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Image.asset('assets/new_icon.png'),
                                ),
                                SizedBox(width: 5.0),
                                Icon(Icons.arrow_downward_rounded, size: 50, color: Colors.grey),
                            ],)
                          ],
                        ),
                      ),
                    );
                  }

                  _bets = bets;

                  return ListView(
                    children: [
                      ...bets.reversed.map((b) => RecentBetContainer(
                        dailyGain: b.dailyGain,
                        bet: b,
                        onDelete: () => _deleteBet(b.id),
                        controller: widget.controller,
                      )),
                      ...priceBets.reversed.map((p) => RecentPriceBetContainer(
                        priceBet: p,
                        onDelete: () => setState(() {}),
                        controller: widget.controller,
                        isForex: Common().isTickerForex(p.ticker),
                      )),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _trendScrollController.dispose();
    _ticker?.dispose;
    super.dispose();
  }
}
