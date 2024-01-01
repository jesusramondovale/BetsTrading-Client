import 'dart:convert';
import 'dart:io';
import 'package:candlesticks/candlesticks.dart';
import 'package:client_0_0_1/locale/localized_texts.dart';
import 'package:image/image.dart' as img;
import '../ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/AuthService.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';

class Common {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  void unimplementedAction(String action, BuildContext aContext) {
    showDialog(
      context: aContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text("Unimplemented action",
              style: TextStyle(color: Colors.white)),
          content: Text(
            'The requested method $action is not implemented yet. Stay tuned',
            style: const TextStyle(fontSize: 16.0, color: Colors.white),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("I'll wait"),
            ),
          ],
        );
      },
    );
  }
  void popDialog(String aTitle, String aBody, BuildContext aContext) {
    showDialog(
      context: aContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
              aTitle,
              style: const TextStyle(color: Colors.white)),
          content: Text(
            aBody,
            style: const TextStyle(fontSize: 16.0, color: Colors.white),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }
  void logInPopDialog(String aTitle, String aUser, BuildContext aContext) {
    showDialog(
      context: aContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
              "$aTitle , $aUser",
              style: const TextStyle(color: Colors.white)),
          actions: [
            ElevatedButton(
              onPressed: () async {
                String? id = await _storage.read(key: 'sessionToken');
                await AuthService().getUserInfo(id!);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainMenuPage()));
              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }
  List<Map<String, String>> getTopCountries() {
    return [
      {'name': 'Afghanistan', 'code': 'AF'},
      {'name': 'Albania', 'code': 'AL'},
      {'name': 'Algeria', 'code': 'DZ'},
      {'name': 'American Samoa', 'code': 'AS'},
      {'name': 'Andorra', 'code': 'AD'},
      {'name': 'Angola', 'code': 'AO'},
      {'name': 'Anguilla', 'code': 'AI'},
      {'name': 'Antarctica', 'code': 'AQ'},
      {'name': 'Antigua-Barbuda', 'code': 'AG'},
      {'name': 'Argentina', 'code': 'AR'},
      {'name': 'Armenia', 'code': 'AM'},
      {'name': 'Aruba', 'code': 'AW'},
      {'name': 'Australia', 'code': 'AU'},
      {'name': 'Austria', 'code': 'AT'},
      {'name': 'Azerbaijan', 'code': 'AZ'},
      {'name': 'Bahamas', 'code': 'BS'},
      {'name': 'Bahrain', 'code': 'BH'},
      {'name': 'Bangladesh', 'code': 'BD'},
      {'name': 'Barbados', 'code': 'BB'},
      {'name': 'Belarus', 'code': 'BY'},
      {'name': 'Belgium', 'code': 'BE'},
      {'name': 'Belize', 'code': 'BZ'},
      {'name': 'Benin', 'code': 'BJ'},
      {'name': 'Bermuda', 'code': 'BM'},
      {'name': 'Bhutan', 'code': 'BT'},
      {'name': 'Bolivia', 'code': 'BO'},
      {'name': 'Bonaire', 'code': 'BQ'},
      {'name': 'Bosnia', 'code': 'BA'},
      {'name': 'Botswana', 'code': 'BW'},
      {'name': 'Bouvet Island', 'code': 'BV'},
      {'name': 'Brazil', 'code': 'BR'},
      {'name': 'British Indian', 'code': 'IO'},
      {'name': 'Brunei Darussalam', 'code': 'BN'},
      {'name': 'Bulgaria', 'code': 'BG'},
      {'name': 'Burkina Faso', 'code': 'BF'},
      {'name': 'Burundi', 'code': 'BI'},
      {'name': 'Cabo Verde', 'code': 'CV'},
      {'name': 'Cambodia', 'code': 'KH'},
      {'name': 'Cameroon', 'code': 'CM'},
      {'name': 'Canada', 'code': 'CA'},
      {'name': 'Cayman Islands', 'code': 'KY'},
      {'name': 'Chad', 'code': 'TD'},
      {'name': 'Chile', 'code': 'CL'},
      {'name': 'China', 'code': 'CN'},
      {'name': 'Christmas Island', 'code': 'CX'},
      {'name': 'Cocos Islands', 'code': 'CC'},
      {'name': 'Colombia', 'code': 'CO'},
      {'name': 'Comoros', 'code': 'KM'},
      {'name': 'Congo', 'code': 'CD'},
      {'name': 'Congo', 'code': 'CG'},
      {'name': 'Cook Islands', 'code': 'CK'},
      {'name': 'Costa Rica', 'code': 'CR'},
      {'name': 'Croatia', 'code': 'HR'},
      {'name': 'Cuba', 'code': 'CU'},
      {'name': 'Curaçao', 'code': 'CW'},
      {'name': 'Cyprus', 'code': 'CY'},
      {'name': 'Czechia', 'code': 'CZ'},
      {'name': 'Côte d\'Ivoire', 'code': 'CI'},
      {'name': 'Denmark', 'code': 'DK'},
      {'name': 'Djibouti', 'code': 'DJ'},
      {'name': 'Dominica', 'code': 'DM'},
      {'name': 'Dominican Republic', 'code': 'DO'},
      {'name': 'Ecuador', 'code': 'EC'},
      {'name': 'Egypt', 'code': 'EG'},
      {'name': 'El Salvador', 'code': 'SV'},
      {'name': 'Equatorial Guinea', 'code': 'GQ'},
      {'name': 'Eritrea', 'code': 'ER'},
      {'name': 'Estonia', 'code': 'EE'},
      {'name': 'Eswatini', 'code': 'SZ'},
      {'name': 'Ethiopia', 'code': 'ET'},
      {'name': 'Falkland Islands', 'code': 'FK'},
      {'name': 'Faroe Islands', 'code': 'FO'},
      {'name': 'Fiji', 'code': 'FJ'},
      {'name': 'Finland', 'code': 'FI'},
      {'name': 'France', 'code': 'FR'},
      {'name': 'French Guiana', 'code': 'GF'},
      {'name': 'French Polynesia', 'code': 'PF'},
      {'name': 'French Southern', 'code': 'TF'},
      {'name': 'Gabon', 'code': 'GA'},
      {'name': 'Gambia', 'code': 'GM'},
      {'name': 'Georgia', 'code': 'GE'},
      {'name': 'Germany', 'code': 'DE'},
      {'name': 'Ghana', 'code': 'GH'},
      {'name': 'Gibraltar', 'code': 'GI'},
      {'name': 'Greece', 'code': 'GR'},
      {'name': 'Greenland', 'code': 'GL'},
      {'name': 'Grenada', 'code': 'GD'},
      {'name': 'Guadeloupe', 'code': 'GP'},
      {'name': 'Guam', 'code': 'GU'},
      {'name': 'Guatemala', 'code': 'GT'},
      {'name': 'Guernsey', 'code': 'GG'},
      {'name': 'Guinea', 'code': 'GN'},
      {'name': 'Guinea-Bissau', 'code': 'GW'},
      {'name': 'Guyana', 'code': 'GY'},
      {'name': 'Haiti', 'code': 'HT'},
      {'name': 'McDonald Islands', 'code': 'HM'},
      {'name': 'Holy See', 'code': 'VA'},
      {'name': 'Honduras', 'code': 'HN'},
      {'name': 'Hong Kong', 'code': 'HK'},
      {'name': 'Hungary', 'code': 'HU'},
      {'name': 'Iceland', 'code': 'IS'},
      {'name': 'India', 'code': 'IN'},
      {'name': 'Indonesia', 'code': 'ID'},
      {'name': 'Iran', 'code': 'IR'},
      {'name': 'Iraq', 'code': 'IQ'},
      {'name': 'Ireland', 'code': 'IE'},
      {'name': 'Isle of Man', 'code': 'IM'},
      {'name': 'Israel', 'code': 'IL'},
      {'name': 'Italy', 'code': 'IT'},
      {'name': 'Jamaica', 'code': 'JM'},
      {'name': 'Japan', 'code': 'JP'},
      {'name': 'Jersey', 'code': 'JE'},
      {'name': 'Jordan', 'code': 'JO'},
      {'name': 'Kazakhstan', 'code': 'KZ'},
      {'name': 'Kenya', 'code': 'KE'},
      {'name': 'Kiribati', 'code': 'KI'},
      {'name': 'Korea (North)', 'code': 'KP'},
      {'name': 'Korea (South)', 'code': 'KR'},
      {'name': 'Kuwait', 'code': 'KW'},
      {'name': 'Kyrgyzstan', 'code': 'KG'},
      {'name': 'Laos', 'code': 'LA'},
      {'name': 'Latvia', 'code': 'LV'},
      {'name': 'Lebanon', 'code': 'LB'},
      {'name': 'Lesotho', 'code': 'LS'},
      {'name': 'Liberia', 'code': 'LR'},
      {'name': 'Libya', 'code': 'LY'},
      {'name': 'Liechtenstein', 'code': 'LI'},
      {'name': 'Lithuania', 'code': 'LT'},
      {'name': 'Luxembourg', 'code': 'LU'},
      {'name': 'Macao', 'code': 'MO'},
      {'name': 'Madagascar', 'code': 'MG'},
      {'name': 'Malawi', 'code': 'MW'},
      {'name': 'Malaysia', 'code': 'MY'},
      {'name': 'Maldives', 'code': 'MV'},
      {'name': 'Mali', 'code': 'ML'},
      {'name': 'Malta', 'code': 'MT'},
      {'name': 'Marshall Islands', 'code': 'MH'},
      {'name': 'Martinique', 'code': 'MQ'},
      {'name': 'Mauritania', 'code': 'MR'},
      {'name': 'Mauritius', 'code': 'MU'},
      {'name': 'Mexico', 'code': 'MX'},
      {'name': 'Micronesia', 'code': 'FM'},
      {'name': 'Moldova', 'code': 'MD'},
      {'name': 'Monaco', 'code': 'MC'},
      {'name': 'Mongolia', 'code': 'MN'},
      {'name': 'Montenegro', 'code': 'ME'},
      {'name': 'Montserrat', 'code': 'MS'},
      {'name': 'Morocco', 'code': 'MA'},
      {'name': 'Mozambique', 'code': 'MZ'},
      {'name': 'Myanmar', 'code': 'MM'},
      {'name': 'Namibia', 'code': 'NA'},
      {'name': 'Netherlands', 'code': 'NL'},
      {'name': 'New Caledonia', 'code': 'NC'},
      {'name': 'New Zealand', 'code': 'NZ'},
      {'name': 'Nicaragua', 'code': 'NI'},
      {'name': 'Niger', 'code': 'NE'},
      {'name': 'Nigeria', 'code': 'NG'},
      {'name': 'Niue', 'code': 'NU'},
      {'name': 'Norfolk Island', 'code': 'NF'},
      {'name': 'Northern Mariana', 'code': 'MP'},
      {'name': 'Norway', 'code': 'NO'},
      {'name': 'Oman', 'code': 'OM'},
      {'name': 'Pakistan', 'code': 'PK'},
      {'name': 'Palau', 'code': 'PW'},
      {'name': 'Palestine', 'code': 'PS'},
      {'name': 'Panama', 'code': 'PA'},
      {'name': 'Papua New Guinea', 'code': 'PG'},
      {'name': 'Paraguay', 'code': 'PY'},
      {'name': 'Peru', 'code': 'PE'},
      {'name': 'Philippines', 'code': 'PH'},
      {'name': 'Pitcairn', 'code': 'PN'},
      {'name': 'Poland', 'code': 'PL'},
      {'name': 'Portugal', 'code': 'PT'},
      {'name': 'Puerto Rico', 'code': 'PR'},
      {'name': 'Qatar', 'code': 'QA'},
      {'name': 'North Macedonia', 'code': 'MK'},
      {'name': 'Romania', 'code': 'RO'},
      {'name': 'Russia', 'code': 'RU'},
      {'name': 'Rwanda', 'code': 'RW'},
      {'name': 'Réunion', 'code': 'RE'},
      {'name': 'Saint Barthélemy', 'code': 'BL'},
      {'name': 'Saint Helena', 'code': 'SH'},
      {'name': 'Saint Kitts and Nevis', 'code': 'KN'},
      {'name': 'Saint Lucia', 'code': 'LC'},
      {'name': 'Saint Martin', 'code': 'MF'},
      {'name': 'Samoa', 'code': 'WS'},
      {'name': 'San Marino', 'code': 'SM'},
      {'name': 'Saudi Arabia', 'code': 'SA'},
      {'name': 'Senegal', 'code': 'SN'},
      {'name': 'Serbia', 'code': 'RS'},
      {'name': 'Seychelles', 'code': 'SC'},
      {'name': 'Sierra Leone', 'code': 'SL'},
      {'name': 'Singapore', 'code': 'SG'},
      {'name': 'Sint Maarten', 'code': 'SX'},
      {'name': 'Slovakia', 'code': 'SK'},
      {'name': 'Slovenia', 'code': 'SI'},
      {'name': 'Solomon Islands', 'code': 'SB'},
      {'name': 'Somalia', 'code': 'SO'},
      {'name': 'South Africa', 'code': 'ZA'},
      {'name': 'South Georgia', 'code': 'GS'},
      {'name': 'South Sudan', 'code': 'SS'},
      {'name': 'Spain', 'code': 'ES'},
      {'name': 'Sri Lanka', 'code': 'LK'},
      {'name': 'Sudan', 'code': 'SD'},
      {'name': 'Suriname', 'code': 'SR'},
      {'name': 'Sweden', 'code': 'SE'},
      {'name': 'Switzerland', 'code': 'CH'},
      {'name': 'Syria', 'code': 'SY'},
      {'name': 'Taiwan', 'code': 'TW'},
      {'name': 'Tajikistan', 'code': 'TJ'},
      {'name': 'Tanzania', 'code': 'TZ'},
      {'name': 'Thailand', 'code': 'TH'},
      {'name': 'Timor-Leste', 'code': 'TL'},
      {'name': 'Togo', 'code': 'TG'},
      {'name': 'Tokelau', 'code': 'TK'},
      {'name': 'Tonga', 'code': 'TO'},
      {'name': 'Trinidad and Tobago', 'code': 'TT'},
      {'name': 'Tunisia', 'code': 'TN'},
      {'name': 'Turkey', 'code': 'TR'},
      {'name': 'Turkmenistan', 'code': 'TM'},
      {'name': 'Turks and Caicos Islands', 'code': 'TC'},
      {'name': 'Tuvalu', 'code': 'TV'},
      {'name': 'Uganda', 'code': 'UG'},
      {'name': 'Ukraine', 'code': 'UA'},
      {'name': 'United Arab Emirates', 'code': 'AE'},
      {'name': 'United Kingdom', 'code': 'GB'},
      {'name': 'United States Islands', 'code': 'UM'},
      {'name': 'United States of America', 'code': 'US'},
      {'name': 'Uruguay', 'code': 'UY'},
      {'name': 'Uzbekistan', 'code': 'UZ'},
      {'name': 'Vanuatu', 'code': 'VU'},
      {'name': 'Venezuela', 'code': 'VE'},
      {'name': 'Viet Nam', 'code': 'VN'},
      {'name': 'Virgin Islands (British)', 'code': 'VG'},
      {'name': 'Virgin Islands (U.S.)', 'code': 'VI'},
      {'name': 'Wallis and Futuna', 'code': 'WF'},
      {'name': 'Western Sahara', 'code': 'EH'},
      {'name': 'Yemen', 'code': 'YE'},
      {'name': 'Zambia', 'code': 'ZM'},
      {'name': 'Zimbabwe', 'code': 'ZW'},
      {'name': 'Åland Islands', 'code': 'AX'},
    ];
  }
  String? getCountryCode(String countryName) {
    var countries = getTopCountries();
    for (var country in countries) {
      if (country['name'] == countryName) {
        return country['code'];
      }
    }
    return null;
  }
  Icon getIconForUserInfo(String key) {
    switch (key) {
      case 'fullname':
        return const Icon(Icons.person);
      case 'username':
        return const Icon(Icons.account_circle);
      case 'email':
        return const Icon(Icons.email);
      case 'birthday':
        return const Icon(Icons.cake);
      case 'address':
        return const Icon(Icons.home);
      case 'country':
        return const Icon(Icons.flag);
      case 'lastsession':
        return const Icon(Icons.access_time);
      default:
        return const Icon(Icons.info_outline);
    }
  }
  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  List<String> getAllGenders(){
    return <String>[
      'Masculine',
      'Feminine',
      'Non-Binary',
      'Cisgender',
      'TDI 1.9',
      'Autobot',
      'Genderqueer',
      'Medabot Type KBT',
      'Sonic the Hedhehog',
      'Agender',
      'Bigender',
      'Napoleón Bonaparte',
      'Doraemon',
      'Transgender',
      'Transfeminine',
      'Decepticon',
      'Transmasculine',
      'LOL',
      'Apache Combat Helicopter',
      'Nigga',
      'Medabot Type KWG',
      'SSD Toshiba 512GB',
      'Neutrois',
      'Dont fucking know',
      'Snorlax',
      // Add more if necessary ...............
    ];
  }
  List<Candle> generateRandomCandles(int count) {
    Random random = Random();
    List<Candle> candlesList = [];
    DateTime startDate = DateTime.now().subtract(Duration(days: count));

    // Inicializa el primer valor de 'open'
    double lastClose = 1.065 + random.nextDouble() * (1.10 - 1.065);

    for (int i = 0; i < count; i++) {
      DateTime date = startDate.add(Duration(days: i));
      double open = lastClose;
      double close = 1.065 + random.nextDouble() * (1.10 - 1.065);
      // Genera porcentajes aleatorios para 'high' y 'low'
      double highPercentage = 0.005 + random.nextDouble() * 0.015; // Entre 0.5% y 2%
      double lowPercentage = 0.005 + random.nextDouble() * 0.015; // Entre 0.5% y 2%
      double high = max(open, close) * (1 + highPercentage);
      high = min(high, 1.10); // Asegura que no sobrepase el máximo de 1.10
      double low = min(open, close) * (1 - lowPercentage);
      low = max(low, 1.065); // Asegura que no sea menor que el mínimo de 1.065
      double volume = random.nextDouble() * 1000;

      lastClose = close;

      candlesList.add(Candle(date: date, open: open, close: close, high: high, low: low, volume: volume));
    }

    return candlesList;
  }
  Future<String> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);
      img.Image originalImage = img.decodeImage(await imageFile.readAsBytes())!;
      if (originalImage.width > 75 || originalImage.height > 75) {
        img.Image resizedImage = img.copyResize(originalImage, width: 75, height: 75);
        List<int> resizedImageBytes = img.encodeJpg(resizedImage);
        return base64Encode(resizedImageBytes);
      } else {
        List<int> imageBytes = await imageFile.readAsBytes();
        return base64Encode(imageBytes);
      }
    } else {
      throw Exception('No image selected.');
    }
  }


}


class BlankImageWidget extends StatelessWidget {
  const BlankImageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Container(
      margin: const EdgeInsets.all(50),
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 300,
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
            Text(strings?.comingSoon ?? "Coming soon..."),
          ],
        ),
      ),
    );
  }
}



