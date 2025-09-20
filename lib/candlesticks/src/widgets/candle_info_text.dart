import '../models/candle.dart';
import '../utils/helper_functions.dart';
import 'package:flutter/material.dart';

class CandleInfoText extends StatelessWidget {
  const CandleInfoText({
    super.key,
    required this.candle,
    required this.bullColor,
    required this.bearColor,
    required this.defaultStyle,
  });

  final Candle candle;
  final Color bullColor;
  final Color bearColor;
  final TextStyle defaultStyle;

  String numberFormat(int value) {
    return "${value < 10 ? 0 : ""}$value";
  }

  String dateFormatter(DateTime date) {
    return "${date.year}-${numberFormat(date.month)}-${numberFormat(date.day)} ${numberFormat(date.hour)}:00";
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: dateFormatter(candle.date),
        style: TextStyle(
          fontSize: 10,
          color: Colors.blueAccent,
        ),
        children: <TextSpan>[
          const TextSpan(text: " O:"),
          TextSpan(
            text: HelperFunctions.priceToString(candle.open),
            style: TextStyle(
              fontSize: 12,
              color: candle.isBull ? bullColor : bearColor,
            ),
          ),
          const TextSpan(text: " H:"),
          TextSpan(
            text: HelperFunctions.priceToString(candle.high),
            style: TextStyle(
              fontSize: 12,
              color: candle.isBull ? bullColor : bearColor,
            ),
          ),
          const TextSpan(text: " L:"),
          TextSpan(
            text: HelperFunctions.priceToString(candle.low),
            style: TextStyle(
              fontSize: 12,
              color: candle.isBull ? bullColor : bearColor,
            ),
          ),
          const TextSpan(text: " C:"),
          TextSpan(
            text: HelperFunctions.priceToString(candle.close),
            style: TextStyle(
              fontSize: 12,
              color: candle.isBull ? bullColor : bearColor,
            ),
          ),
        ],
      ),
    );
  }
}
