import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../Services/BetsService.dart';
import '../config/config.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import '../native_rewarded.dart';
import '../services/AuthService.dart';
import 'layout_page.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class StorePage extends StatefulWidget {
  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  final InAppPurchase _iap = InAppPurchase.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();

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
                _showPaymentOptions(context, 100, 1.99);
              },
            ),
            _buildStoreButton(
              context,
              strings,
              coins: 500,
              price: 7.99,
              onPressed: () {
                _showPaymentOptions(context, 500 , 7.99 );
              },
            ),
            _buildStoreButton(
              context,
              strings,
              coins: 1000,
              price: 14.99,
              onPressed: () {
                _showPaymentOptions(context, 1000,  14.99);
              },
            ),
            _buildStoreButton(
              context,
              strings,
              coins: 5000,
              price: 59.99,
              onPressed: () {
                _showPaymentOptions(context, 5000 , 59.99);
              },
            ),
            SizedBox(height: 30),
            Divider(),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isAdLoaded
                  ? () {  Common().vibrate(40, 30);
              _showRewardedAd(50, Common().interpolate(strings.getMessage('youWonCoins') ?? 'You won 50฿!', {
                'coins': 50.toString(), }));
              }
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
                  Common().interpolate(strings.getMessage('earnCoins') ??
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

  void _loadRewardedAd() {
    RewardedAd.load(
      //TODO: Use only ADMBOD_AD_TOKEN (not _TEST) in production
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

    if (userId == null) {
      print('No hay userId, no se puede mostrar el anuncio.');
      return;
    }

    try {

      //TODO: Use only ADMBOD_AD_TOKEN (not _TEST) in production
      await NativeRewarded.loadRewarded(Config.ADMOB_AD_TOKEN_TEST, userId);

      final reward = await NativeRewarded.showRewarded();

      /** TODO: Delete this addCoins call when using real ADMBOD_AD_TOKEN with SSV :
       * All the business logic goes into -> (Backend .NET) PaymentsController:59 (HTTP GET VerifyAd)
       * will be called by GoogleAdmob system automatically when user finishes watching real ads
       * D E L E T E   M E -->**/ await AuthService().addCoins(userId, coins); /** **/
      /******  ******  ******* ******** ******** ******  ******* *********   *******/



      if (reward != null && reward > 0) {
        Common().showLocalNotification(
          "other",
          "Betrader",
          localizedWarning,
          {"REWARD": reward},
        );

        await BetsService().getUserInfo(userId);
        Navigator.pop(context);
        homeScreenKey.currentState?.loadUserIdAndData();
      } else {
        print('El anuncio no devolvió recompensa.');
      }
    } catch (e) {
      print('Error mostrando anuncio recompensado: $e');
    }
  }

  Widget _buildStoreButton(
      BuildContext context,
      LocalizedStrings strings, {
        required int coins,
        required double price,
        required VoidCallback onPressed,
      }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15.0),
      child: Card(
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
            Common().interpolate(strings.getMessage('buyCoins') ?? 'Buy {coins} Coins', {
              'coins': coins.toString(),
            }),
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w200,
              fontSize: 20.0,
            ),
          ),
          trailing: Text(
            Common().interpolate(strings.getMessage('priceInEuros') ?? '€{price}', {
              'price': price.toStringAsFixed(2),
            }),
            style: GoogleFonts.roboto(
              fontSize: 18.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentOptions(BuildContext context, double coins, double price) {

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(LocalizedStrings.of(context)?.paymentOptionsTitle ?? "How do you want to pay?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.credit_card),
                title: Text(LocalizedStrings.of(context)?.payWithCard ?? 'Credit or Debit card'),
                onTap: () {
                  Navigator.pop(context);
                  _cardPayment(coins, price);
                },
              ),
              ListTile(
                leading: Image.asset('assets/paypal.png', height: 24.0),
                title: Text('PayPal'),
                onTap: () {
                  Navigator.pop(context);
                  //_payPalPayment(price);
                },
              ),
              ListTile(
                leading: Image.asset(
                  'assets/google.png',
                  height: 24.0,
                  fit: BoxFit.contain,
                ),
                title: Text('Google Play'),
                onTap: () {
                  Navigator.pop(context);
                  _buyFromGooglePlay('test');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cardPayment(double coins, double price) async {
    try {
      String? userId = await _storage.read(key: 'sessionToken');
      final billingDetails = stripe.BillingDetails(
        email: 'betsontrading@gmail.com',
        phone: '',
        address: stripe.Address(
          city: 'Carreño',
          country: 'ES',
          line1: '',
          line2: '',
          postalCode: '33430',
          state: 'Asturias'
        ),
      );

      final clientSecret = await _getClientSecret(price, userId!, coins);

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.dark,
          merchantDisplayName: 'Betrader',
          billingDetails: billingDetails,
          googlePay: stripe.PaymentSheetGooglePay(
            merchantCountryCode: 'ES',
            currencyCode: 'EUR',
          ),
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();

      await BetsService().getUserInfo(userId);
      Navigator.pop(context);
      homeScreenKey.currentState?.loadUserIdAndData();

      //TODO: Check real complete before to notify user
      /** No excepion means transaction OK? */

      Common().showLocalNotification(
        "other",
        "Betrader",
        Common().interpolate(LocalizedStrings.of(context)!.youEarnedCoins ?? 'You earned ${coins}฿!', { 'coins': coins.toString() }),
        {"REWARD": coins},
      );

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 3),
          content: Text("Error! Cannot process transaction"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _buyFromGooglePlay(String productId) async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      print("❌ Google Play no disponible");
      return;
    }

    final ProductDetailsResponse response = await _iap.queryProductDetails({productId});
    if (response.notFoundIDs.isNotEmpty) {
      print("❌ Producto no encontrado en Play Console");
      return;
    }

    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

    _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  Future<String> _getClientSecret(double price, String userId, double coins) async {
    final Map<String, dynamic> requestData = {
      'amount': (price * 100).toInt(),
      'currency': "eur",
      'userId': userId,
      'coins': coins,
    };

    final response = await Common().postRequestWrapper(
      'Payments',
      'CreatePaymentIntent',
      requestData,
    );

    if (response['statusCode'] == 200 && response['body'] != null && response['body']['client_secret'] != null) {
      return response['body']['client_secret'];
    } else {
      throw Exception('Error al obtener client_secret desde el backend');
    }
  }

}
