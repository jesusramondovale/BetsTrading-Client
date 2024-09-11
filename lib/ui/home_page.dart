// ignore_for_file: constant_identifier_names, prefer_const_constructors

import 'package:auto_size_text/auto_size_text.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/models/favorites.dart';
import 'package:betrader/services/BetsService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../helpers/common.dart';
import '../models/bets.dart';
import '../models/trends.dart';
import 'layout_page.dart';

class HomeScreen extends StatefulWidget {
  final MainMenuPageController controller;
  const HomeScreen({super.key, required this.controller});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool showFavorites = false;
  List<Bet> _bets = [];
  String _userId = "none";
  String _userPoints = '0';

  Future<void> _loadUserIdAndData() async {
    final userId = await _storage.read(key: "sessionToken") ?? "none";
    final userPoints = await _storage.read(key: "points") ?? "0";
    setState(() {
      _userId = userId;
      _userPoints = userPoints;
    });
    _loadBets(userId);
  }

  Future<void> _loadBets(String userId) async {
    final betsData = await BetsService().fetchInvestmentData(userId);
    setState(() {
      _bets = betsData.investList;
    });
  }

  void _deleteBet(int betId) {
    setState(() {
      _bets.removeWhere((bet) => bet.id == betId);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserIdAndData();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    Locale locale = Localizations.localeOf(context);
    String formattedDate =
        DateFormat.yMMMMd(locale.toString()).format(DateTime.now());

    return Scaffold(
      key: _homeScreenKey,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Upper icons
            Row(
              children: [
                Card(
                  elevation: 0,
                  surfaceTintColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isRealNotifier,
                    builder: (context, isReal, child) {
                      return Row(
                        children: [
                          Switch(
                            value: isReal,
                            inactiveThumbColor: Colors.black,
                            inactiveTrackColor: Colors.grey,
                            onChanged: (bool value) {
                              isRealNotifier.value = value;
                            },
                          ),
                          if (isReal) ...[
                            SizedBox(width: 5),
                            Image.asset('assets/alpha_vantage.png', width: 35),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                Spacer(flex: 10),
                Image.asset(Theme.of(context).brightness == Brightness.dark
                    ? 'assets/betrader-BETA_dark.png' : 'assets/betrader-BETA_light.png' , width: 120),
                Spacer(),
                IconButton(
                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                  icon: showFavorites
                      ? Icon(Icons.star)
                      : Icon(Icons.star_border),
                  iconSize: 30,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey
                      : Colors.black,
                  onPressed: () {
                    triggerFavorites();
                  },
                ),
                IconButton(
                  padding: const EdgeInsets.all(2.5),
                  onPressed: () {
                    ///TO-DO
                  },
                  icon: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, Colors.grey.shade800], // Color normal
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _userPoints,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),

            // Trends
            Row(
              children: <Widget>[
                Text(strings?.liveBets ?? 'Trends',
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
                    fontWeight: Theme.of(context).brightness == Brightness.dark
                        ? FontWeight.w200
                        : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
            ),
            Divider(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                thickness: 0.5,
                height: 0.5),
            Expanded(
              flex: showFavorites ? 9 : 2,
              child: FutureBuilder<Trends>(
                  future: BetsService().fetchTrendsData(_userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.grey),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.hasData &&
                        snapshot.data!.trends.isNotEmpty) {
                      final data = snapshot.data!;
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          List<Trend> sortedTrends = List.from(data.trends)
                            ..sort((a, b) => a.id.compareTo(b.id));
                          int sortedIndex = sortedTrends[index].id - 1;
                          return TrendContainer(
                              trend: sortedTrends[index],
                              index: sortedIndex,
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
                              Icon(
                                Icons.wifi_off_sharp,
                                size: 90,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }),
            ),

            // Favorites
            if (showFavorites) ...[
              Text(strings!.favs ?? 'Favs',
                  style: GoogleFonts.comfortaa(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  )),
              Divider(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  thickness: 0.5,
                  height: 0.5),
              Expanded(
                flex: 8,
                child: FutureBuilder<Favorites>(
                    future: BetsService().fetchFavouritesData(_userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.grey),
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
                                  LocalizedStrings.of(context)!.noFavsYet ??
                                      "No favorites yet!",
                                  style: GoogleFonts.dosis(
                                    fontSize: 18,
                                    fontWeight: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? FontWeight.w200
                                        : FontWeight.w400,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Icon(
                                  Icons.star_border,
                                  size: 50,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }),
              ),
            ],

            // Recent bets
            Text(
              strings?.recentBets ?? 'Recent Bets',
              style: GoogleFonts.comfortaa(
                  fontSize: 20, fontWeight: FontWeight.w400),
            ),
            Divider(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                thickness: 0.5,
                height: 0.5),
            Expanded(
              flex: showFavorites ? 12 : 5,
              child: FutureBuilder<Bets>(
                  future: BetsService().fetchInvestmentData(_userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.grey),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.hasData &&
                        snapshot.data!.investList.isNotEmpty) {
                      final data = snapshot.data!;
                      _bets = data.investList;
                      return ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: _bets.length,
                        itemBuilder: (context, index) {
                          return RecentBetContainer(
                              bet: _bets[index],
                              onDelete: () => _deleteBet(_bets[index].id), controller: widget.controller,);
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
                                strings?.noLiveBets ??
                                    'You have no live bets at the moment, go to the markets tab to create a new one.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 30),
                              const Icon(
                                Icons.auto_graph,
                                size: 40,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void triggerFavorites() {
    setState(() {
      showFavorites = (showFavorites ? false : true);
    });
  }

  void refreshFavorites() {
    setState(() {
      showFavorites = true;
    });
  }
}
