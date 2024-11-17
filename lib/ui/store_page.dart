import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../locale/localized_texts.dart';

class StorePage extends StatefulWidget {
  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
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
                //TODO: Acción para comprar 100 monedas
              },
            ),
            _buildStoreButton(
              context,
              strings,
              coins: 500,
              price: 7.99,
              onPressed: () {
                //TODO: Acción para comprar 500 monedas
              },
            ),
            _buildStoreButton(
              context,
              strings,
              coins: 1000,
              price: 14.99,
              onPressed: () {
                //TODO: Acción para comprar 1000 monedas
              },
            ),
            _buildStoreButton(
              context,
              strings,
              coins: 5000,
              price: 59.99,
              onPressed: () {
                //TODO: Acción para comprar 5000 monedas
              },
            ),
            SizedBox(height: 30),
            Divider(),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                //TODO: Acción para ganar monedas viendo un anuncio
              },
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
