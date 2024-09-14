import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SlideToConfirm extends StatefulWidget {
  final double betAmount;
  final String icon;
  final VoidCallback onSlideComplete;

  const SlideToConfirm({
    Key? key,
    required this.betAmount,
    required this.icon,
    required this.onSlideComplete,
  }) : super(key: key);

  @override
  _SlideToConfirmState createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _sliderValue = 0.0;
  ui.Image? _thumbImage;

  @override
  void initState() {
    super.initState();
    _loadImage(widget.icon);
  }

  // Cargar la imagen a partir de base64
  void _loadImage(String base64String) async {
    Uint8List bytes = base64Decode(base64String);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    _thumbImage = await completer.future;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
                alignment: Alignment.topCenter,
                child: Text(
                  '${widget.betAmount.toStringAsFixed(2)}฿',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (_thumbImage != null)
              SliderTheme(
                data: SliderThemeData(
                  thumbShape: _CustomThumbShape(_thumbImage!),
                  trackHeight: 40.0,
                  thumbColor: Colors.transparent,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.green[700]?.withAlpha(128),
                ),
                child: Slider(
                  value: _sliderValue,
                  onChanged: (value) {
                    setState(() {
                      _sliderValue = value;
                    });
                  },
                  onChangeEnd: (value) {
                    if (value == 1.0) {
                      widget.onSlideComplete();
                    } else {
                      // Si no llega al final, vuelve a 0
                      setState(() {
                        _sliderValue = 0.0;
                      });
                    }
                  },
                  min: 0.0,
                  max: 1.0,
                ),
              )
            else
              const CircularProgressIndicator(), // Indicador de carga mientras se decodifica la imagen
          ],
        ),
      ],
    );
  }
}

class _CustomThumbShape extends SliderComponentShape {
  final ui.Image thumbImage;

  _CustomThumbShape(this.thumbImage);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(40, 40); // Tamaño del thumb
  }

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

    // Dibuja la imagen del thumb en el slider
    final Rect thumbRect = Rect.fromCenter(center: center, width: 60, height: 60);
    paintImage(
      canvas: canvas,
      image: thumbImage,
      rect: thumbRect,
      fit: BoxFit.fitWidth,
    );
  }
}
