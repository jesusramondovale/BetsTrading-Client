import 'dart:math';
import 'dart:math' as math;

import '../constant/view_constants.dart';

class HelperFunctions {
  static double log10(num x) => log(x) / ln10;

  static double getRoof(double number) {
    if (number == 0) {
      return 1;
    }
    int log = log10(number).floor();
    return (number ~/ pow(10, log) + 1) * pow(10, log).toDouble();
  }

  static String addMetricPrefix(double price) {
    if (price < 1) price = 1;
    int log = log10(price).floor();
    if (log > 9) {
      return "${price ~/ 1000000000}B";
    } else if (log > 6) {
      return "${price ~/ 1000000}M";
    } else if (log > 3) {
      return "${price ~/ 1000}K";
    } else {
      return price.toStringAsFixed(0);
    }
  }

  static String priceToString(double price, {int currency = 0, int extraDecimals = 0}) {
    final abs = price.abs();

    // límite superior de decimales según magnitud (tu misma lógica, pero centralizada)
    final int maxDecimals =
    abs > 1000 ? 2 :
    abs > 100  ? 3 :
    abs > 10   ? 4 :
    abs > 1    ? 5 :
    abs > 0.1  ? 6 :
    7;

    int decimals = _decimalsBySecondSignificant(abs, maxDecimals);
    if (extraDecimals > 0) {
      decimals = math.min(decimals + extraDecimals, maxDecimals + extraDecimals);
    }

    final formatted = price.toStringAsFixed(decimals);
    final suffix = currency == 0 ? '' : (currency == 1 ? '€' : '\$');
    return '$formatted$suffix';
  }

  static int _decimalsBySecondSignificant(double absPrice, int maxDecimals) {
    if (absPrice == 0) return math.min(2, maxDecimals);

    final s = absPrice.toStringAsFixed(maxDecimals);
    final dot = s.indexOf('.');
    if (dot < 0) {
      return math.min(2, maxDecimals);
    }

    int firstNonZeroPos = -1;
    for (int i = dot + 1; i < s.length; i++) {
      final c = s[i];
      if (c != '0') {
        firstNonZeroPos = i - (dot + 1);
        break;
      }
    }

    if (firstNonZeroPos == -1) {
      return math.min(2, maxDecimals);
    }

    int decimals = firstNonZeroPos + 2;

    if (decimals < 2) decimals = 2;
    if (decimals > maxDecimals) decimals = maxDecimals;

    return decimals;
  }

  /// Decimales extra para que dos precios separados por [step] no se vean iguales.
  static int extraDecimalsForStep(double price, double step) {
    if (!step.isFinite || step.abs() < 1e-12) return 0;
    var extra = 0;
    while (extra < 3 &&
        priceToString(price, extraDecimals: extra) ==
            priceToString(price - step, extraDecimals: extra)) {
      extra++;
    }
    return extra;
  }

  /// Paso de la escala de precios. Nunca devuelve 0, infinito ni NaN:
  /// el primer frame del gráfico puede llegar con high == low.
  static double calculatePriceScale(double height, double high, double low) {
    final double safeHeight =
        height.isFinite && height > 0 ? height : minPricetileHeight * 2;
    int minTiles = (safeHeight / minPricetileHeight).floor();
    minTiles = max(2, minTiles);

    double sizeRange = high - low;
    if (!sizeRange.isFinite || sizeRange <= 0) {
      final double basis = high.isFinite
          ? high.abs()
          : (low.isFinite ? low.abs() : 1);
      sizeRange = max(basis * 0.01, 1e-6);
    }

    double minStepSize = sizeRange / minTiles;
    if (!minStepSize.isFinite || minStepSize <= 0) minStepSize = 1e-6;

    final double logStep = log10(minStepSize);
    if (!logStep.isFinite) return minStepSize;

    final double base = pow(10, logStep.floor()).toDouble();
    if (!base.isFinite || base <= 0) return minStepSize;

    if (2 * base > minStepSize) return 2 * base;
    if (5 * base > minStepSize) return 5 * base;
    return 10 * base;
  }
}
