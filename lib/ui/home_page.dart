// ignore_for_file: constant_identifier_names, prefer_const_constructors

import 'package:auto_size_text/auto_size_text.dart';
import 'package:client_0_0_1/locale/localized_texts.dart';
import 'package:client_0_0_1/models/favorites.dart';
import 'package:client_0_0_1/services/BetsService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../helpers/common.dart';
import '../models/bets.dart';
import '../models/trends.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {

  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool showFavorites = false;

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    Future<String> getUserId() async {
      return await _storage.read(key: "sessionToken") ?? "none";
    }

    Locale locale = Localizations.localeOf(context);
    String formattedDate =
        DateFormat.yMMMMd(locale.toString()).format(DateTime.now());

    return Scaffold(
      key: _homeScreenKey,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Upper icons
            Row(
              children: [
                Spacer(),
                IconButton(
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
                  icon: Icon(Icons.local_grocery_store_rounded),
                  iconSize: 30,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey
                      : Colors.black,
                  onPressed: () {
                    Common().unimplementedAction(context);
                  },
                ),
              ],
            ),

            // Trends
            Row(
              children: <Widget>[
                Text(strings?.liveBets ?? 'Trends',
                    style: GoogleFonts.comfortaa(
                      fontSize: 24,
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
              child: FutureBuilder<String>(
                  future: getUserId(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(child: Text("Error or no user ID"));
                    } else {
                      final userId = snapshot.data!;
                      return FutureBuilder<Trends>(
                          future: BetsService().fetchTrendsData(userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.grey),
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
                                  List<Trend> sortedTrends =
                                      List.from(data.trends)
                                        ..sort((a, b) => a.id.compareTo(b.id));
                                  int sortedIndex = sortedTrends[index].id - 1;
                                  return TrendContainer(
                                    trend: sortedTrends[index],
                                    index: sortedIndex,
                                      onFavoriteUpdated: refreshFavorites
                                  );
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
                          });
                    }
                  }),
            ),

            // Favorites
            if (showFavorites) ...[
              Text('Favs',
                  style: GoogleFonts.comfortaa(
                    fontSize: 24,
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
                child: FutureBuilder<String>(
                    future: getUserId(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child:
                                CircularProgressIndicator(color: Colors.grey));
                      } else if (snapshot.hasError || !snapshot.hasData) {
                        return const Center(child: Text("Error or no user ID"));
                      } else {
                        final userId = snapshot.data!;
                        return FutureBuilder<Favorites>(
                            future: BetsService().fetchFavouritesData(userId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.grey),
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
                                        onFavoriteUpdated: refreshFavorites
                                    );
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
                                          LocalizedStrings.of(context)!.noFavsYet ?? "No favorites yet!",
                                          style: GoogleFonts.dosis(
                                            fontSize: 18,
                                            fontWeight: Theme.of(context).brightness == Brightness.dark
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
                            });
                      }
                    }),
              ),
            ],

            // Recent bets
            Text(
              strings?.recentBets ?? 'Recent Bets',
              style: GoogleFonts.comfortaa(
                  fontSize: 24, fontWeight: FontWeight.w400),
            ),
            Divider(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                thickness: 0.5,
                height: 0.5),
            Expanded(
              flex: showFavorites ? 12 : 5,
              child: FutureBuilder<String>(
                  future: getUserId(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: Colors.grey));
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(child: Text("Error or no user ID"));
                    } else {
                      final userId = snapshot.data!;
                      return FutureBuilder<Bets>(
                          future: BetsService().fetchInvestmentData(userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.grey),
                              );
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (snapshot.hasData &&
                                snapshot.data!.investList.isNotEmpty) {
                              final data = snapshot.data!;
                              return ListView.builder(
                                scrollDirection: Axis.vertical, //LMAO
                                itemCount: data.investList.length,
                                itemBuilder: (context, index) {
                                  return RecentBetContainer(
                                      bet: data.investList[index]);
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
                          });
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

  void refreshFavorites(){
    setState(() {
      showFavorites = true;
    });
  }
}






