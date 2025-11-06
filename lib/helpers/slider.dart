import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common.dart';
import 'package:intl/intl.dart' as intl;

class SlideToConfirm extends StatefulWidget {
  final double betAmount;
  final double? transformedAmount;
  final String icon;
  final VoidCallback onSlideComplete;
  final bool transformThumb;
  final bool scaleUp;
  final bool disabled;

  const SlideToConfirm({
    Key? key,
    required this.betAmount,
    this.transformedAmount,
    required this.icon,
    required this.onSlideComplete,
    this.scaleUp = false,
    this.transformThumb = false,
    this.disabled = false,
  }) : super(key: key);

  @override
  _SlideToConfirmState createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _sliderValue = 0.0;
  ui.Image? _thumbImage;
  ui.Image? _euroImage;
  String _currency = 'eur';

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

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('dollarCurrency') ?? false){
      _currency = 'usd';
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
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('dollarCurrency') ?? false) {
      _currency = 'usd';
    }
    ByteData data = await rootBundle.load(_currency == 'eur' ? "assets/euro.png" : "assets/dollar.png");
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

    final amountColor = widget.disabled ? Colors.red : null;

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
                        Icon(Icons.double_arrow, size: 30, color: amountColor ?? Colors.black)
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
                            color: amountColor,
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
                          color: amountColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Image.asset(
                        (_currency == 'eur' ? 'assets/euro.png' : 'assets/dollar.png'),
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
                      scaleUpIcon: widget.scaleUp
                  ),
                  trackHeight: 40.0,
                  thumbColor: Colors.transparent,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.green[700]?.withAlpha(128),
                ),
                child: Slider(
                  divisions: 50,
                  value: _sliderValue,
                  onChanged: widget.disabled
                      ? (value) {
                    Common().vibrate(400, 100);
                    setState(() => _sliderValue = 0);
                    }
                      : (value) {
                    int intensity = (10 + (95 * value)).round();
                    Common().vibrate(40, intensity);
                    setState(() => _sliderValue = value);
                  },
                  onChangeEnd: widget.disabled
                      ? null
                      : (value) {
                    if (value == 1.0) {
                      widget.onSlideComplete();
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (mounted) setState(() => _sliderValue = 0.0);
                      });
                    } else {
                      Common().vibrate();
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
  final bool scaleUpIcon;

  _FadeThumbShape({
    required this.baseImage,
    this.transformImage,
    required this.transformProgress,
    required this.useFade,
    required this.scaleUpIcon
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
    final thumbRect = Rect.fromCenter(center: center,
        width: scaleUpIcon ? 120.0 : 80.0,
        height: scaleUpIcon ? 120.0 : 80.0 );
    final inner = thumbRect.deflate(8);

    if (useFade && transformImage != null) {
      final t = transformProgress.clamp(0.0, 1.0);
      canvas.saveLayer(thumbRect, Paint());
      paintImage(
        canvas: canvas,
        image: baseImage,
        rect: inner,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        opacity: 1.0 - t*1.1,
      );
      paintImage(
        canvas: canvas,
        image: transformImage!,
        rect: inner,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        opacity: t*1.1,
      );
      canvas.restore();
    } else {
      paintImage(
        canvas: canvas,
        image: baseImage,
        rect: inner,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }
  }
}
