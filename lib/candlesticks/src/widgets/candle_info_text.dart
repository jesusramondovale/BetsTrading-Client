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
    final priceStyle = TextStyle(
      fontSize: 12,
      height: 1.15,
      color: candle.isBull ? bullColor : bearColor,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "(${((candle.close - candle.open) / candle.open * 100).abs().toStringAsFixed(2)}%)",
                style: TextStyle(
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.bold,
                  color: candle.close >= candle.open ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "O: ${HelperFunctions.priceToString(candle.open)}",
                style: priceStyle,
              ),
              const SizedBox(width: 12),
              Text(
                "C: ${HelperFunctions.priceToString(candle.close)}",
                style: priceStyle,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateFormatter(candle.date.isUtc ? candle.date.toLocal() : candle.date),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.15,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "H: ${HelperFunctions.priceToString(candle.high)}",
                style: priceStyle,
              ),
              const SizedBox(width: 12),
              Text(
                "L: ${HelperFunctions.priceToString(candle.low)}",
                style: priceStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
