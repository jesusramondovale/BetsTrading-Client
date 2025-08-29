import 'package:auto_size_text/auto_size_text.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/models/favorites.dart';
import 'package:betrader/services/BetsService.dart';
import 'package:betrader/ui/settings_view.dart';
import 'package:betrader/ui/store_page.dart';
import 'package:flutter/material.dart';
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
  String _userId = "none";
  double _userPoints = 0;
  bool showFavorites = true;

  Future<void> loadUserIdAndData() async {
    final userId = await _storage.read(key: "sessionToken") ?? "none";
    final userPoints = await _storage.read(key: "points") ?? "0";
    setState(() {
      _userId = userId;
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
      showFavorites = true;
    });
  }

  @override
  void initState() {
    super.initState();
    loadUserIdAndData();
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
                    Common().vibrate(40,30);

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
                    Common().vibrate(40,30);
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
                              onFavoriteUpdated: refreshFavorites,
                              controller: widget.controller,);
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
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }),
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
                        Common().vibrate(40,30);
                        bool result = await BetsService().deleteHistoricBets(_userId);
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
                  Common().vibrate(40,30),
                  await BetsService().getUserInfo(_userId),
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
              child: FutureBuilder<BetsAndPriceBets>(
                future: BetsService().fetchInvestmentData(_userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.grey));
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
                                  'You have no live bets at the moment, go to the markets tab to create a new one.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey,
                              ),
                            ),
                            Icon(Icons.arrow_downward_rounded, size: 50, color: Colors.grey),
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

}
