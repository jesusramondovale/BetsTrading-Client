import 'package:flutter/material.dart';

/// Slider track shape for exchange page sliders.
/// This is in a separate file to avoid type conflicts with helper sliders.
class ExchangeSliderTrackShape extends SliderTrackShape {
  const ExchangeSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      parentBox.size.width,
      0,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    // No pintar nada, el track es transparente
  }
}

/// Slider thumb shape for exchange page sliders.
/// This is in a separate file to avoid type conflicts with helper sliders.
class ExchangeSliderThumbShape extends SliderComponentShape {
  const ExchangeSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(0, 0);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required Size sizeWithOverflow,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double textScaleFactor,
    required double value,
  }) {
    // No pintar nada, el thumb es invisible
  }
}
