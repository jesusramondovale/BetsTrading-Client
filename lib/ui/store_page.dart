import 'package:betrader/services/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../Services/BetsService.dart';
import '../config/config.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import 'layout_page.dart';

class StorePage extends StatefulWidget {
  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();

  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: Config.ADMOB_AD_TOKEN_TEST,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          print('Error loading ad: $error');
        },
      ),
    );
  }

  Future<void> _showRewardedAd(double coins, String localizedWarning) async {
    String? userId = await _storage.read(key: 'sessionToken');
    if (_rewardedAd == null) {
      print('Ad not loaded.');
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        setState(() async {
          print('Reward earned: ${reward.amount} ${reward.type}');
          bool success = await AuthService().addCoins(userId!, coins);
          if (success) {
            Common().showLocalNotification(
                "Betrader",
                ( localizedWarning ),  {"REWARD": 50});

            await BetsService().getUserInfo(userId);

            Navigator.pop(context);

            homeScreenKey.currentState?.loadUserIdAndData();

          }

        });
      },
    );

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        print('Error al mostrar el anuncio: $error');
        _loadRewardedAd();
      },
    );

    _rewardedAd = null;
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          strings!.getMessage('store') ?? 'Store',
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStoreButton(
              context,
              strings,
              coins: 100,
              price: 1.99,
              onPressed: () {
                // Acción para comprar 100 monedas
              },
            ),
            _buildStoreButton(
              context,
              strings,
              coins: 500,
              price: 7.99,
              onPressed: () {
                // Acción para comprar 500 monedas
              },
            ),
            _buildStoreButton(
              context,
              strings,
              coins: 1000,
              price: 14.99,
              onPressed: () {
                // Acción para comprar 1000 monedas
              },
            ),
            _buildStoreButton(
              context,
              strings,
              coins: 5000,
              price: 59.99,
              onPressed: () {
                // Acción para comprar 5000 monedas
              },
            ),
            SizedBox(height: 30),
            Divider(),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isAdLoaded
                  ? () =>_showRewardedAd(50, _interpolate(strings.getMessage('youWonCoins') ?? 'You won 50฿!', {
                                         'coins': 50.toString(), }))
                  : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(Icons.play_circle_fill, size: 34),
              label: Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Text(
                  _interpolate(strings.getMessage('earnCoins') ??
                      'Watch an Ad to Earn {coins}฿', {
                    'coins': '50',
                  }),
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreButton(
      BuildContext context,
      LocalizedStrings strings, {
        required int coins,
        required double price,
        required VoidCallback onPressed,
      }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 5,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        leading: CircleAvatar(
          radius: 30,
          child: Text(
            '$coins',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.amber,
        ),
        title: Text(
          _interpolate(strings.getMessage('buyCoins') ?? 'Buy {coins} Coins', {
            'coins': coins.toString(),
          }),
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w200,
            fontSize: 20.0,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: Text(
            _interpolate(strings.getMessage('priceInEuros') ?? '€{price}', {
              'price': price.toStringAsFixed(2),
            }),
            style: GoogleFonts.roboto(fontSize: 18.0),
          ),
        ),
      ),
    );
  }

  String _interpolate(String template, Map<String, String> values) {
    values.forEach((key, value) {
      template = template.replaceAll('{$key}', value);
    });
    return template;
  }
}
