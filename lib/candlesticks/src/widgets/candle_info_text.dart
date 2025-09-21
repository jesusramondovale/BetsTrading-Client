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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila superior -> % , O y C
        Row(
          children: [
            SizedBox(
              width: 85,
              child: Text(
                "(${((candle.close - candle.open) / candle.open * 100).abs().toStringAsFixed(2)}%)",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: candle.close >= candle.open ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.right, // alineado a la derecha en el hueco
              ),
            ),
            const SizedBox(width: 14),
            Text(
              "O: ${HelperFunctions.priceToString(candle.open)}",
              style: TextStyle(
                fontSize: 12,
                color: candle.isBull ? bullColor : bearColor,
              ),
            ),
            const SizedBox(width: 20),
            Text(
              "C: ${HelperFunctions.priceToString(candle.close)}",
              style: TextStyle(
                fontSize: 12,
                color: candle.isBull ? bullColor : bearColor,
              ),
            ),
          ],
        ),
        // Fila inferior -> fecha, H y L
        Row(
          children: [
            Text(
              dateFormatter(candle.date),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              "H: ${HelperFunctions.priceToString(candle.high)}",
              style: TextStyle(
                fontSize: 12,
                color: candle.isBull ? bullColor : bearColor,
              ),
            ),
            const SizedBox(width: 20),
            Text(
              "L: ${HelperFunctions.priceToString(candle.low)}",
              style: TextStyle(
                fontSize: 12,
                color: candle.isBull ? bullColor : bearColor,
              ),
            ),
          ],
        ),
      ],
    );


  }
}
