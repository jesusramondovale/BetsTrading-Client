import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'common.dart';
import 'package:intl/intl.dart' as intl;

class SlideToConfirm extends StatefulWidget {
  final double betAmount;
  final double? transformedAmount;
  final String icon;
  final VoidCallback onSlideComplete;
  final bool transformThumb;

  const SlideToConfirm({
    Key? key,
    required this.betAmount,
    this.transformedAmount,
    required this.icon,
    required this.onSlideComplete,
    this.transformThumb = false,
  }) : super(key: key);

  @override
  _SlideToConfirmState createState() => _SlideToConfirmState();
}


class _SlideToConfirmState extends State<SlideToConfirm> {
  double _sliderValue = 0.0;
  ui.Image? _thumbImage;
  ui.Image? _euroImage;

  @override
  void initState() {
    super.initState();
    _loadInitialThumb();
    if (widget.transformThumb) {
      _loadEuroImage();
    }
  }

  Future<void> _loadInitialThumb() async {
    if (widget.icon.startsWith("http")) {
      _loadImageFromUrl(widget.icon);
    } else if (widget.icon != "null") {
      _loadImageFromBase64(widget.icon);
    } else {
      _loadSimpleLogoImage();
    }
  }

  Future<void> _loadSimpleLogoImage() async {
    ByteData data = await rootBundle.load("assets/new_icon.png");
    Uint8List bytes = data.buffer.asUint8List();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) => completer.complete(img));
    _thumbImage = await completer.future;
    if (mounted) setState(() {});
  }

  Future<void> _loadImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Uint8List bytes = response.bodyBytes;
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(bytes, (ui.Image img) => completer.complete(img));
        _thumbImage = await completer.future;
        if (mounted) setState(() {});
      } else {
        _loadSimpleLogoImage();
      }
    } catch (_) {
      _loadSimpleLogoImage();
    }
  }

  Future<void> _loadImageFromBase64(String base64String) async {
    Uint8List bytes = base64Decode(base64String);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) => completer.complete(img));
    _thumbImage = await completer.future;
    if (mounted) setState(() {});
  }

  Future<void> _loadEuroImage() async {
    ByteData data = await rootBundle.load("assets/euro.png");
    Uint8List bytes = data.buffer.asUint8List();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) => completer.complete(img));
    _euroImage = await completer.future;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final double totalWidth = renderBox?.size.width ?? MediaQuery.of(context).size.width;
    final double thumbX = _sliderValue * totalWidth;

    final bool passedCenter = thumbX >= totalWidth * 0.45;

    final bool showEurosInstead = widget.transformedAmount != null && passedCenter;

    final bothImagesLoaded =
        _thumbImage != null && (!widget.transformThumb || _euroImage != null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Align(
                alignment: Alignment.center,
                child: AnimatedCrossFade(
                  firstChild: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.betAmount == -1) ...[
                        Icon(Icons.double_arrow, size: 30)
                      ]
                      else ...[
                        Text(
                          (widget.transformThumb == true ?
                          intl.NumberFormat.compact().format(widget.betAmount)
                              :
                          (widget.betAmount % 1 == 0
                              ? widget.betAmount.toInt().toString()
                              : widget.betAmount.toStringAsFixed(2)) ),
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Image.asset(
                          "assets/coin.png",
                          width: 28,
                          height: 28,
                        ),
                      ]

                    ],
                  ),
                  secondChild: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.transformedAmount?.toStringAsFixed(0) ?? '',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Image.asset(
                        "assets/euro.png",
                        width: 28,
                        height: 28,
                      ),
                    ],
                  ),
                  crossFadeState: showEurosInstead
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 500),
                  firstCurve: Curves.easeOutBack,
                  secondCurve: Curves.easeOutBack,
                ),
              ),

            ),
            if (bothImagesLoaded)
              SliderTheme(
                data: SliderThemeData(
                  thumbShape: _FadeThumbShape(
                    baseImage: _thumbImage!,
                    transformImage: _euroImage,
                    transformProgress: _sliderValue,
                    useFade: widget.transformThumb,
                  ),
                  trackHeight: 40.0,
                  thumbColor: Colors.transparent,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.green[700]?.withAlpha(128),
                ),
                child: Slider(
                  divisions: 50,
                  value: _sliderValue,
                  onChanged: (value) {
                    int intensity = (10 + (95 * value)).round();
                    Common().vibrate(40, intensity);
                    setState(() => _sliderValue = value);
                  },
                  onChangeEnd: (value) {
                    if (value == 1.0) {
                      widget.onSlideComplete();
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (mounted) setState(() => _sliderValue = 0.0);
                      });
                    } else {
                      Common().vibrate(40, 50);
                      setState(() => _sliderValue = 0.0);
                    }
                  },
                  min: 0.0,
                  max: 1.0,
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ],
    );
  }

}

class _FadeThumbShape extends SliderComponentShape {
  final ui.Image baseImage;
  final ui.Image? transformImage;
  final double transformProgress;
  final bool useFade;

  _FadeThumbShape({
    required this.baseImage,
    this.transformImage,
    required this.transformProgress,
    required this.useFade,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(60, 60);

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
    final Canvas canvas = context.canvas;
    final rect = Rect.fromCenter(center: center, width: 60, height: 60);

    if (useFade && transformImage != null) {
      final paint1 = Paint()..color = Colors.white.withValues(alpha: 1.0 - transformProgress);
      final paint2 = Paint()..color = Colors.white.withValues(alpha: transformProgress);

      canvas.saveLayer(rect, Paint());
      paintImage(canvas: canvas, image: baseImage, rect: rect, fit: BoxFit.fitWidth, opacity: paint1.color.a);
      paintImage(canvas: canvas, image: transformImage!, rect: rect, fit: BoxFit.fitWidth, opacity: paint2.color.a);
      canvas.restore();
    } else {
      paintImage(canvas: canvas, image: baseImage, rect: rect, fit: BoxFit.fitWidth);
    }
  }
}
