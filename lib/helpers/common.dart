import 'dart:convert';
import 'dart:io';
import 'package:betrader/candlesticks/candlesticks.dart';
import 'package:betrader/helpers/slider.dart';
import 'package:betrader/models/rectangle_zone.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/models/favorites.dart';
import 'package:betrader/services/BetsService.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import '../main.dart';
import '../models/betZone.dart';
import '../models/bets.dart';
import '../models/trends.dart';
import '../ui/layout_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import '../config/config.dart';
import 'package:http/http.dart' as http;


class Common {

  final ThemeData themeDark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      background: Colors.black,
      onBackground: Colors.black54,
      surface: Colors.black,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      color: Colors.black,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),


    ),

  );
  final ThemeData themeLight = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      background: Colors.white,
      onBackground: Colors.grey.withOpacity(0.5),
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      color: Colors.white,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),

    ),
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Future<void> showLocalNotification(String title, String body, Map<String,dynamic> payload) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(Random().toString(), 'Betrader', importance: Importance.max, priority: Priority.high);
    NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    print("showLocalNotification! $body");
    await flutterLocalNotificationsPlugin.show(
      Random().nextInt(64),
      title,
      body,
      platformChannelSpecifics,
      payload: payload.toString()
    );
  }
  void unimplementedAction(BuildContext aContext,  [String? text = '']) {
        ScaffoldMessenger.of(aContext).showSnackBar(
      SnackBar(content: Text('Action is not implemented yet ${text!}'), duration: const Duration(milliseconds: 1300),),
    );
  }
  void actionDialog(BuildContext aContext,  [String? text = '']) {
    ScaffoldMessenger.of(aContext).showSnackBar(
      SnackBar(content: Text(text!), duration: const Duration(milliseconds: 1300),),
    );
  }
  void newFavoriteCompleted(BuildContext aContext, String localizedText) {
    ScaffoldMessenger.of(aContext).showSnackBar(
      SnackBar(content: Text(localizedText), duration: const Duration(milliseconds: 2500),),
    );
  }
  void popDialog(String aTitle, String aBody, BuildContext aContext) {
    showDialog(
      context: aContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.grey[200]!,
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
  Future<bool?> popConfirmOperationDialog(BuildContext aContext, double betAmount, String betIcon) async {
    return await showDialog<bool>(
      context: aContext,
      builder: (BuildContext context) {
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop(false);
            return false;
          },
          child: AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.grey[200]!,
            title: Text(
              LocalizedStrings.of(context)!.confirmOperation ?? "Confirm operation",
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.roboto(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w400),
            ),
            content: Text(
              LocalizedStrings.of(context)!.confirmBet ?? "Slide to confirm the operation",
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(fontSize: 14.0, color: Colors.white),
            ),
            actions: [
              SlideToConfirm(
                icon: betIcon,
                betAmount: betAmount,
                onSlideComplete: () {
                  Navigator.of(context).pop(true);
                },
              )
            ],
          ),
        );
      },
    );
  }
  void exitPopDialog(String aTitle, String aBody, BuildContext aContext) {
    showDialog(
      barrierColor: Colors.black.withAlpha(220),
      context: aContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.grey[200]!,
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
                if (Platform.isAndroid) {
                  SystemNavigator.pop();
                } else if (Platform.isIOS) {
                  exit(0);
                }
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
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.grey[200]!,
          title: Text(
              "$aTitle , $aUser",
              style: const TextStyle(color: Colors.white)),
          actions: [
            ElevatedButton(
              onPressed: () async {
                String? id = await _storage.read(key: 'sessionToken');
                await BetsService().getUserInfo(id!);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainMenuPage()));

              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }
  double calculateMaxFontSize(String text, FontWeight fontWeight, double maxWidth) {
    double fontSize = 18;
    double foundFontSize = fontSize;
    bool fits = false;
    while (!fits && fontSize > 0) {

      TextStyle textStyle = TextStyle(fontWeight: fontWeight, fontSize: fontSize);
      TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      if (textPainter.width <= maxWidth) {
        foundFontSize = fontSize;
        fits = true;
      } else {
        fontSize -= 1;
      }
    }

    return foundFontSize;
  }
  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
  String _getRandomIconPath(){

    const iconPaths = [
      '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eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iCiAgICB4bWxuczpzdEV2dD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlRXZlbnQjIgogICAgeG1sbnM6R0lNUD0iaHR0cDovL3d3dy5naW1wLm9yZy94bXAvIgogICAgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIgogICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iCiAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iCiAgIHhtcE1NOkRvY3VtZW50SUQ9ImdpbXA6ZG9jaWQ6Z2ltcDowZjE3YjQyNS1lZWUwLTQzMDUtYjkwOS1hYzhkMjQyMWY1MmQiCiAgIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6YjlkNjIyYjgtZWY3Ni00MGJmLWJiNGQtMWIxNWFjYzMzNWFiIgogICB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6NzgzMWEyM2UtZjRlNi00M2Q1LTk3NmYtNmYzZWU4OWFkMzFkIgogICBHSU1QOkFQST0iMi4wIgogICBHSU1QOlBsYXRmb3JtPSJXaW5kb3dzIgogICBHSU1QOlRpbWVTdGFtcD0iMTcxNzc4NjU2MjU0NTE0MCIKICAgR0lNUDpWZXJzaW9uPSIyLjEwLjM2IgogICBkYzpGb3JtYXQ9ImltYWdlL3BuZyIKICAgdGlmZjpPcmllbnRhdGlvbj0iMSIKICAgeG1wOkNyZWF0b3JUb29sPSJHSU1QIDIuMTAiCiAgIHhtcDpNZXRhZGF0YURhdGU9IjIwMjQ6MDY6MDdUMjA6NTY6MDIrMDI6MDAiCiAgIHhtcDpNb2RpZnlEYXRlPSIyMDI0OjA2OjA3VDIwOjU2OjAyKzAyOjAwIj4KICAgPHhtcE1NOkhpc3Rvcnk+CiAgICA8cmRmOlNlcT4KICAgICA8cmRmOmxpCiAgICAgIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiCiAgICAgIHN0RXZ0OmNoYW5nZWQ9Ii8iCiAgICAgIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6ZWNhMGZjYjctZDk5OS00MmNmLWExNTUtZTJlNWI1MTgyYjJiIgogICAgICBzdEV2dDpzb2Z0d2FyZUFnZW50PSJHaW1wIDIuMTAgKFdpbmRvd3MpIgogICAgICBzdEV2dDp3aGVuPSIyMDI0LTA2LTA3VDIwOjU2OjAyIi8+CiAgICA8L3JkZjpTZXE+CiAgIDwveG1wTU06SGlzdG9yeT4KICA8L3JkZjpEZXNjcmlwdGlvbj4KIDwvcmRmOlJERj4KPC94OnhtcG1ldGE+CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAKPD94cGFja2V0IGVuZD0idyI/PgAHczQAAAAGYktHRAD/AP8A/6C9p5MAAAAJcEhZcwAADdgAAA3YATTmNWIAAAAHdElNRQfoBgcSOALCZ1SfAAAgAElEQVR42u3dd5wcd33/8ffM7O71Kt3p1HVnSZasZrnKFXDBNjY2mJJADIZQQsCBX8LvF0NCiBMTSggQegiB0CE4GAzG2IAr2JaLLMuWLMmWpVO93m/vts18f3+srGLdna7s3c7Mvp6Phx6STtJp9zPf/X7e850mAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABwchYlAILF6201JhmXUnEpNSgvEZdSAzLJASk1IHlpyctI7pAkyaTj2a9JslLd2a+ZpJTpzX7DSLUsqyj79Vht9mt2VFa0LPtrp1SyI5IdlWIVsooqpFiF7OIyKVYuxcpkFZXJrm5gPgEIAAAm3NgHuowZ6pGJd8kMdsoMdUjx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008/PRoN0NoAv1CY6UEASoRZBABkXNgY1d2D//a3v3HPgE2If830uHLlyui5jxYJDx06tMrrHU7HAoAGZBYBABnnFwjrSvVVV11FJ2AzY71+F198cdLo1xQsjQiEN2wDgAZmFgEAGed3Ddpzzz3d9OnT46YrqUuqmxKkLVc/++wzN2DAgOg11miA6DVXR4ARAQAlwiwCACqAFgvfeuutjAZsYqzXzd934fLLL0/WBPgOAPcQAFBizCIAoAKMHDnSzZkzJ2q4hvELYUntCV+rsGPQo0eP5HX204GYFgSgxJhFAEDGaU/7p59+Om625obtQfOPNSqgOzP70QD/qOlATAkCUGLMIgAg43r37p3scrN06dLokeSftWvXxs82ZMWKFdGjXku/LWt492atEVBHYKuttmJkAECpMIsAgDKnBqd/HjY8/Xx1P5edbFo0ErB8+fL4o43RTdm48g+gTJhFAECZU2PfT0sRTQXyz3/4wx+yQLhACTtU06ZNc0cccQQdAQDlwiwCADJAuwL5523bto0et9lmG/f+++/HTVeyufn666/jZ86NHj2aTgCAcmIWAQAZ4O9mG97V9uyzz2Y0oADxIwH+XgKff/65GzJkSJXXGwBKmFkEAGRI69ato0eNBnzwwQdRw5UUNjfccEMyGsD9AgCUCbMIAMgIrRVo0aJF9Py0005jNKAeMnnyZDd06NDoNdZi7HBtBgCUMLMIAMgIf3VaowHjxo2Lm66kUPn222/dOeecw2gAgHJkFgEAZc43TJs1axY97r///twxuB7y9ttvJwux/SMAlAmzCADIgH79+iXPNX2F1C1+IbBiTanSfQT69+8fvb7t27ePHrlZGIAyYhYBABnQpk2b6HHYsGFuwYIFcfOV5BN/p+CabrymBcJNmjSJXmO/U1B4N2EAKHFmEQBQ5vydhdUZuO6661gkXMesWbMmeqxuVODTTz91Xbt2jV7jli1bJq+7FgpzLwEAZcIsAgDKnO8I7L333m7KlClx85VsTvwogaK7M/sGvx8N8K859xEAUCbMIgAgIy6++OLkSjajApuecKH13//+92SL0LDR7zsCAFAmzCIAIANatWrlnnnmmbj5WvN8d5JfJk2a5AYMGBC9vloPoMXB4VQgtg8FUEbMIgAgA4444ohon/t06BDULf710i5Bp556atTw33rrrZMOgDoDfoSA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'];

    return iconPaths[Random().nextInt(iconPaths.length)];

  }
  Bet generateRandomBet([double? odds]) {
    final random = Random();
    final id = random.nextInt(10000); // ID aleatorio entre 0 y 9999
    final ticker = _generateRandomString(16); // Cadena de 16 caracteres aleatorios
    final name = 'Asset ${id}'; // Nombre basado en el ID
    final iconPath = _getRandomIconPath(); // Path al azar
    final betAmount = random.nextDouble() * 10000; // Monto de apuesta aleatorio entre 0 y 10000
    final originValue = random.nextDouble() * 1000; // Valor original aleatorio entre 0 y 1000
    final currentValue = random.nextDouble() * 1000; // Valor actual aleatorio entre 0 y 1000
    final targetValue = originValue + (random.nextDouble() * 100); // Valor objetivo mayor que el original
    final targetMargin = random.nextDouble() * 20; // Margen de objetivo aleatorio entre 0 y 20%
    final targetDate = DateTime.now().add(Duration(days: random.nextInt(365))); // Fecha objetivo en el próximo año
    final endDate = targetDate.add(Duration(days: 2));
    final targetOdds = (odds != null ? odds : (random.nextDouble() * 20) + 1); // Probabilidades entre 1 y 21

    return Bet(
      currentValue, false, currentValue-originValue,
      id: id,
      dailyGain: 1.0,
      ticker: ticker,
      name: name,
      iconPath: iconPath,
      betAmount: betAmount,
      originValue: originValue,
      targetValue: targetValue,
      targetMargin: targetMargin,
      targetDate: targetDate, 
      endDate: endDate,
      targetOdds: targetOdds,
      bet_zone: 999
    );
  }
  int daysUntilLatestEndDate(List<RectangleZone> rectangleZones) {
    if (rectangleZones.isEmpty) {
      return 10;
    }
    DateTime latestDate = rectangleZones.first.endDate;

    for (var zone in rectangleZones) {
      if (zone.endDate.isAfter(latestDate)) {
        latestDate = zone.endDate;
      }
    }
    DateTime now = DateTime.now();
    int daysUntil = latestDate.difference(now).inDays;
    return daysUntil > 0 ? daysUntil : 0;
  }
  List<RectangleZone> getRectangleZonesFromBetZones(List<BetZone> betZones, double current) {
    Color strokeColor = Colors.white;

    List<RectangleZone> zones = betZones.map((betZone) {
      //TO-DO
      // Determinar el color de relleno basado en algún criterio
      Color fillColor;
      if (betZone.targetValue > current) {
        fillColor = Colors.green.withOpacity(0.4);
      } else {
        fillColor = Colors.red.withOpacity(0.4);
      }

      return RectangleZone(
        id: betZone.id,
        startDate: betZone.startDate,
        endDate: betZone.endDate ?? DateTime.now().add(const Duration(days: 1)),
        highPrice: betZone.targetValue + (betZone.targetValue * betZone.betMargin/200),
        lowPrice: betZone.targetValue - (betZone.targetValue * betZone.betMargin/200),
        margin: betZone.betMargin,
        fillColor: fillColor,
        strokeColor: strokeColor,
        odds: betZone.targetOdds,
        ticker: betZones.first.ticker,

      );
    }).toList();

    return zones;
  }
  List<RectangleZone> generateRectangleZones() {
    Color strokeColor = Colors.white;
    List<RectangleZone> zones = [
      RectangleZone(
          id: 99999999,
          startDate: DateTime.now().add(const Duration(days: 15)),
          endDate: DateTime.now().add(const Duration(days: 20)),
          highPrice: 1.2,
          lowPrice: 1.12,
          fillColor: Colors.green.withOpacity(0.4),
          strokeColor: strokeColor,
          odds: (Random().nextDouble()*25),
          margin: 5, ticker: ''

      ),

      RectangleZone(
          id : 9999999995,
          startDate: DateTime.now().add(const Duration(days: 9)),
          endDate: DateTime.now().add(const Duration(days: 20)),
          highPrice: 1.25,
          lowPrice: 1.2,
          fillColor: Colors.green.withOpacity(0.6),
          strokeColor: strokeColor,
          odds: (Random().nextDouble()*25),
          margin: 5, ticker: ''

      ),


      RectangleZone(
          id: 9899999999,
          startDate: DateTime.now().add(const Duration(days: 7)),
          endDate: DateTime.now().add(const Duration(days: 20)),
          highPrice: 1.05,
          lowPrice: 0.95,
          fillColor: Colors.red.withOpacity(0.4),
          strokeColor: strokeColor,
          odds: (Random().nextDouble()*25),
          margin: 5, ticker: ''

      ),


      RectangleZone(
          id: 9898889999999,
          startDate: DateTime.now().add(const Duration(days: 4)),
          endDate: DateTime.now().add(const Duration(days: 20)),
          highPrice: 0.95,
          lowPrice: 0.8,
          fillColor: Colors.red.withOpacity(0.6),
          strokeColor: strokeColor,
          odds: (Random().nextDouble()*25),
          margin: 5, ticker: ''

      ),


    ];

    return zones;
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
  String getCountryCode(String countryName) {
    var countries = getTopCountries();
    for (var country in countries) {
      if (country['name'] == countryName) {
        return country['code'] ?? '?';
      }
    }
    return '?';
  }
  ImageProvider getProfileImage(String? profilePic) {
    if (profilePic != null) {
      if (profilePic.startsWith('https')) {
        return NetworkImage(profilePic);
      } else {
        return MemoryImage(base64Decode(profilePic));
      }
    } else {
      return MemoryImage(base64Decode(
          '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TU0AKgAAABBFeGlmTWV0YQAEARoABQAAAAEAAABGARsABQAAAAEAAABOASgAAwAAAAEAAgAAAhMAAwAAAAEAAQAAAAAAAAAAASwAAAABAAABLAAAAAFYTVAg1wMAADw/eHBhY2tldCBiZWdpbj0n77u/JyBpZD0nVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkJz8+Cjx4OnhtcG1ldGEgeG1sbnM6eD0nYWRvYmU6bnM6bWV0YS8nIHg6eG1wdGs9J0ltYWdlOjpFeGlmVG9vbCAxMS44OCc+CjxyZGY6UkRGIHhtbG5zOnJkZj0naHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyc+CgogPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9JycKICB4bWxuczp0aWZmPSdodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyc+CiAgPHRpZmY6UmVzb2x1dGlvblVuaXQ+MjwvdGlmZjpSZXNvbHV0aW9uVW5pdD4KICA8dGlmZjpYUmVzb2x1dGlvbj4zMDAvMTwvdGlmZjpYUmVzb2x1dGlvbj4KICA8dGlmZjpZUmVzb2x1dGlvbj4zMDAvMTwvdGlmZjpZUmVzb2x1dGlvbj4KIDwvcmRmOkRlc2NyaXB0aW9uPgoKIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PScnCiAgeG1sbnM6eG1wPSdodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvJz4KICA8eG1wOkNyZWF0b3JUb29sPkFkb2JlIFN0b2NrIFBsYXRmb3JtPC94bXA6Q3JlYXRvclRvb2w+CiA8L3JkZjpEZXNjcmlwdGlvbj4KCiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0nJwogIHhtbG5zOnhtcE1NPSdodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vJz4KICA8eG1wTU06RG9jdW1lbnRJRD54bXAuaWlkOjJhY2VhNDcxLTRjOWMtNGNjNC05YzhmLThlOTM4OWY5NjA0MDwveG1wTU06RG9jdW1lbnRJRD4KICA8eG1wTU06SW5zdGFuY2VJRD5hZG9iZTpkb2NpZDpzdG9jazphNzdmMDNlYi01YTJjLTQ1MWItODJjOS0wOTZkODU5YjJiNzM8L3htcE1NOkluc3RhbmNlSUQ+CiAgPHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD5hZG9iZTpkb2NpZDpzdG9jazo1ODk5MzI3ODI8L3htcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD4KIDwvcmRmOkRlc2NyaXB0aW9uPgo8L3JkZjpSREY+CjwveDp4bXBtZXRhPgo8P3hwYWNrZXQgZW5kPSd3Jz8+AA=='));
    }
  }
  String getCountryName(String countryCode) {
    var countries = getTopCountries();
    for (var country in countries) {
      if (country['code'] == countryCode) {
        return country['name'] ?? '?';
      }
    }
    return '?';
  }
  RegExp getIDRegExpByCountry(String countryCode){
    RegExp idExp;
    switch (countryCode.toUpperCase()) {
      case 'ES': // España - DNI (8 dígitos y 1 letra)
        idExp = RegExp(r'\b\d{8}[A-Z]\b');
        break;
      case 'IT': // Italia - Codice Fiscale (16 caracteres: letras y números)
        idExp = RegExp(r'\b[A-Z0-9]{16}\b');
        break;
      case 'FR': // Francia - INSEE (15 dígitos)
        idExp = RegExp(r'\b\d{15}\b');
        break;
      case 'DE': // Alemania - Personalausweisnummer (9 caracteres: letras y números)
        idExp = RegExp(r'\b[A-Z0-9]{9}\b');
        break;
      case 'US': // Estados Unidos - Social Security Number (SSN) (XXX-XX-XXXX)
        idExp = RegExp(r'\b\d{3}-\d{2}-\d{4}\b');
        break;
      case 'UK': // Reino Unido - National Insurance Number (2 letras, 6 dígitos, 1 letra)
        idExp = RegExp(r'\b[A-Z]{2}\d{6}[A-D]\b');
        break;
      case 'CA': // Canadá - Social Insurance Number (SIN) (XXX-XXX-XXX)
        idExp = RegExp(r'\b\d{3}-\d{3}-\d{3}\b');
        break;
      case 'AU': // Australia - Tax File Number (TFN) (9 dígitos)
        idExp = RegExp(r'\b\d{9}\b');
        break;
      case 'BR': // Brasil - Cadastro de Pessoas Físicas (CPF) (XXX.XXX.XXX-XX)
        idExp = RegExp(r'\b\d{3}\.\d{3}\.\d{3}-\d{2}\b');
        break;
      case 'IN': // India - Aadhaar (12 dígitos)
        idExp = RegExp(r'\b\d{4}\s\d{4}\s\d{4}\b');
        break;
      case 'MX': // México - Clave Única de Registro de Población (CURP) (18 caracteres alfanuméricos)
        idExp = RegExp(r'\b[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\b');
        break;
      case 'JP': // Japón - Número My Number (12 dígitos)
        idExp = RegExp(r'\b\d{12}\b');
        break;
      case 'CN': // China - Número de Identidad (18 dígitos)
        idExp = RegExp(r'\b\d{17}[\dX]\b');
        break;
      case 'RU': // Rusia - Número de Pasaporte Interno (10 dígitos)
        idExp = RegExp(r'\b\d{10}\b');
        break;
      case 'ZA': // Sudáfrica - ID (13 dígitos)
        idExp = RegExp(r'\b\d{13}\b');
        break;
      case 'AR': // Argentina - DNI (8 dígitos)
        idExp = RegExp(r'\b\d{8}\b');
        break;
      case 'CO': // Colombia - Cédula de Ciudadanía (XXX.XXX.XXX)
        idExp = RegExp(r'\b\d{3}\.\d{3}\.\d{3}\b');
        break;
      case 'CL': // Chile - RUN (XX.XXX.XXX-X)
        idExp = RegExp(r'\b\d{1,2}\.\d{3}\.\d{3}-[\dkK]\b');
        break;
      case 'PE': // Perú - DNI (8 dígitos)
        idExp = RegExp(r'\b\d{8}\b');
        break;
      case 'VE': // Venezuela - Cédula de Identidad (X.XXX.XXX)
        idExp = RegExp(r'\b\d1\.\d{3}\.\d{3}\b');
        break;
      default: // Default: ID de 8 dígitos
        idExp = RegExp(r'\b\d{8}\b');
        break;
    }
    return idExp;

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
  List<Candle> generateConstantCandles(int count) {
    List<Candle> candlesList = [];
    DateTime startDate = DateTime.now();

    for (int i = 0; i < count; i++) {
      DateTime date = startDate.subtract(Duration(days: i));
      double open = 1.0;
      double close = 1.0;
      double high = 1.0;
      double low = 1.0;
      double volume = 1000.0;

      candlesList.add(Candle(
        date: date,
        open: open,
        close: close,
        high: high,
        low: low,
        volume: volume,
      ));
    }

    return candlesList;
  }
  List<Candle> generateRandomCandles(int count, double price) {
    Random random = Random();
    List<Candle> candlesList = [];
    DateTime startDate = DateTime.now();

    // Inicializa el primer valor de 'open'
    double lastClose = price + random.nextDouble() * (1.10 - 1.065);

    for (int i = 0; i < count; i++) {
      DateTime date = startDate.subtract(Duration(days: i));
      double open = lastClose;

      // Generar cierre de la vela con variación
      double close = open + (random.nextBool() ? 1 : -1) * (0.0001 + random.nextDouble() * (price * 0.01));

      // Proporcionalidad del rango alto-bajo basada en el precio pasado
      double maxChange = price * 0.05;  // 5% de variación con respecto al precio original

      double high = max(open, close) + random.nextDouble() * maxChange;
      double low = min(open, close) - random.nextDouble() * maxChange;

      // Generar volumen aleatorio
      double volume = 500 + random.nextDouble() * 4500;

      // Actualizar el cierre anterior
      lastClose = close;

      // Añadir vela a la lista
      candlesList.add(Candle(date: date, open: open, close: close, high: high, low: low, volume: volume));
    }

    return candlesList;
  }
  List<Candle> generateSinusoidalCandles(int count, double centerValue, double amplitude, double period) {
    List<Candle> candlesList = [];
    DateTime startDate = DateTime.now();

    for (int i = 0; i < count; i++) {
      DateTime date = startDate.subtract(Duration(days: i));

      double sinValue = sin(2 * pi * i / period) * amplitude;

      double open = centerValue + sinValue;
      double close = centerValue + sinValue + (Random().nextBool() ? 1 : -1) * Random().nextDouble() * 5;
      double high = max(open, close) + Random().nextDouble() * 10;
      double low = min(open, close) - Random().nextDouble() * 10;
      double volume = 500 + Random().nextDouble() * 4500;

      candlesList.add(Candle(
        date: date,
        open: open,
        close: close,
        high: high,
        low: low,
        volume: volume,
      ));
    }

    return candlesList;
  }
  RectangleZone emptyZone(){
    return RectangleZone(
        id: 989888999999,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        highPrice: 1.0,
        lowPrice: 0.0,
        fillColor: Colors.green.withOpacity(0.4),
        strokeColor: Colors.white,
        odds: 0.0,
        margin: 0, ticker: ''

    );
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
  List<FlSpot> createRandomSpots(int count) {
    final random = Random();
    return List.generate(count, (index) => FlSpot(
      index.toDouble(),
      double.parse((random.nextDouble() * 10).toStringAsFixed(2)),
    ));
  }
  bool isBullSpots(List<FlSpot> spots) {
    if (spots.length < 2) {
      throw ArgumentError('Need at least two spots to compare.');
    }
    return spots.last.y > spots.first.y;
  }
  String createTrendViewName(Trend t) {
    String viewName = "";
    List<String> words = t.name.split(' ');
    for (int i = 0; i < words.length && i < 3; i++) {
      if (words[i].isNotEmpty) {
        viewName += words[i][0];
      }
    }
    return viewName;
  }
  String createTrendViewNameFromName(String name) {
    String viewName = "";
    List<String> words = name.split(' ');
    for (int i = 0; i < words.length && i < 3; i++) {
      if (words[i].isNotEmpty) {
        viewName += words[i][0];
      }
    }
    return viewName;
  }
  String createFavViewName(Favorite f) {
    String viewName = "";
    List<String> words = f.name.split(' ');
    for (int i = 0; i < words.length && i < 3; i++) {
      if (words[i].isNotEmpty) {
        viewName += words[i][0];
      }
    }
    return viewName;
  }
  String createViewName(String s) {
    List<String> words = s.split(' ');
    return words[0];
  }
  Future<Map<String, dynamic>> postRequestWrapper(String controller, String endpoint, Map<String, dynamic> data) async {
    try {
      bool certificateCheck(X509Certificate cert, String host, int port) => true;
      HttpClient client = HttpClient()..badCertificateCallback = certificateCheck;

      final HttpClientRequest request = await client.postUrl(Uri.parse("https://${Config.PUBLIC_DOMAIN}:${Config.SERVICE_PORT}/api/$controller/$endpoint"));
      request.headers.set('Content-Type', 'application/json charset=utf-8');
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();

      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(responseBody)
      };
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 111 || e.osError?.errorCode == 7) {
        return {'statusCode': 503, 'body': {}};
      }
      return {'statusCode': 500, 'body': {}};
    } catch (e) {
      return {'statusCode': 500, 'body': {}};
    }
  }
  Future<String> getUserCountry() async {
    final apiKey = Config.IP_GEOLOCALIZER_TOKEN;
    final url = 'https://ipinfo.io/json?token=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final country = data['country'];
        print('User country: $country');
        return country;
      } else {
        print('Failed to get geolocation information, status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return 'null';
      }
    } catch (error) {
      print('Error getting geolocation information: $error');
      return 'null';
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






