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

class BetAmountSelector extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final double initialValue;
  final ValueChanged<double> onChanged;
  final double? maxAllowedValue;

  const BetAmountSelector({
    Key? key,
    this.minValue = 0.0,
    this.maxValue = 5000.0,
    this.initialValue = 0.0,
    required this.onChanged,
    this.maxAllowedValue,
  }) : super(key: key);

  @override
  _BetAmountSelectorState createState() => _BetAmountSelectorState();
}

class _BetAmountSelectorState extends State<BetAmountSelector> {
  late double _sliderValue;
  ui.Image? _thumbImage;

  @override
  void initState() {
    super.initState();
    _loadDefaultImage();
    _initializeSliderValue();
  }

  void _initializeSliderValue() {
    // El effectiveMax es el máximo permitido + 1 para mostrar el rango extendido
    final baseMax = widget.maxAllowedValue != null 
        ? (widget.maxAllowedValue! < widget.maxValue ? widget.maxAllowedValue! : widget.maxValue)
        : widget.maxValue;
    final effectiveMax = baseMax + 1.0; // Añadir 1 al máximo para el rango extendido
    final range = effectiveMax - widget.minValue;
    
    if (range > 0 && baseMax > 0) {
      // Calcular el valor inicial como máximo/4, redondeado al múltiplo de 10 más cercano
      final quarterMax = baseMax / 4.0;
      final roundedValue = (quarterMax / 10.0).round() * 10.0;
      // Asegurarse de que esté dentro del rango válido
      final initialValue = roundedValue.clamp(widget.minValue, baseMax);
      
      // Convertir el valor a la posición del slider (0.0 a 1.0)
      _sliderValue = ((initialValue - widget.minValue) / range).clamp(0.0, 1.0);
      
      // Notificar al widget padre del valor inicial calculado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(initialValue);
        }
      });
    } else {
      _sliderValue = 0.0;
    }
  }

  Future<void> _loadDefaultImage() async {
    ByteData data = await rootBundle.load("assets/new_icon.png");
    Uint8List bytes = data.buffer.asUint8List();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) => completer.complete(img));
    _thumbImage = await completer.future;
    if (mounted) setState(() {});
  }

  // Función para hacer "snap" a valores que terminan en 00 o 50
  double _snapToRoundValues(double value) {
    if (value <= 0) return value;
    
    // Solo aplicar snap para valores mayores a 50 para evitar problemas con valores pequeños
    if (value < 50) return value;
    
    // Rango de tolerancia para el snap (10 unidades)
    const double snapTolerance = 10.0;
    
    // Encontrar el múltiplo de 50 más cercano
    final nearestFifty = (value / 50).round() * 50.0;
    final distanceToFifty = (value - nearestFifty).abs();
    
    // Verificar si el múltiplo de 50 más cercano termina en 00 o 50
    final remainder = nearestFifty % 100;
    final isRoundValue = (remainder == 0 || remainder == 50);
    
    // Aplicar snap si está cerca de un valor que termina en 00 o 50
    // Y asegurarse de que no sea 0 (para valores pequeños)
    if (isRoundValue && distanceToFifty <= snapTolerance && nearestFifty > 0) {
      return nearestFifty;
    }
    
    // Si no está cerca de ningún valor especial, devolver el valor original
    return value;
  }

  void _adjustValue(double delta) {
    final baseMax = widget.maxAllowedValue != null 
        ? (widget.maxAllowedValue! < widget.maxValue ? widget.maxAllowedValue! : widget.maxValue)
        : widget.maxValue;
    final effectiveMax = baseMax + 1.0;
    final range = effectiveMax - widget.minValue;
    
    // Obtener el valor actual
    final currentValue = widget.minValue + (_sliderValue * range);
    // Ajustar el valor
    final newValue = (currentValue + delta).clamp(widget.minValue, effectiveMax);
    // Redondear a múltiplos de 5
    final roundedValue = (newValue / 5).round() * 5.0;
    final finalValue = roundedValue.clamp(widget.minValue, effectiveMax);
    
    // Actualizar el slider value
    final newSliderValue = range > 0 
        ? ((finalValue - widget.minValue) / range).clamp(0.0, 1.0)
        : 0.0;
    
    setState(() {
      _sliderValue = newSliderValue;
    });
    widget.onChanged(finalValue);
    Common().vibrate(20, 30);
  }

  @override
  Widget build(BuildContext context) {
    // El effectiveMax es el máximo permitido + 1 para mostrar el rango extendido
    final baseMax = widget.maxAllowedValue != null 
        ? (widget.maxAllowedValue! < widget.maxValue ? widget.maxAllowedValue! : widget.maxValue)
        : widget.maxValue;
    final effectiveMax = baseMax + 1.0; // Añadir 1 al máximo para el rango extendido
    final clampedValue = _sliderValue.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_thumbImage != null)
          Stack(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  thumbShape: _BetAmountThumbShape(image: _thumbImage!),
                  trackHeight: 50.0,
                  thumbColor: Colors.transparent,
                  activeTrackColor: Colors.green[700]?.withValues(alpha: 0.3),
                  inactiveTrackColor: Colors.grey[700]?.withValues(alpha: 0.2),
                ),
                child: Slider(
                  divisions: ((effectiveMax - widget.minValue) / 5).round().clamp(1, 1000), // Incrementos de 5, máximo 1000 divisiones para rendimiento
                  value: clampedValue,
                  onChanged: (value) {
                    final rawValue = widget.minValue + (value * (effectiveMax - widget.minValue));
                    // Redondear a múltiplos de 5
                    final roundedValue = (rawValue / 5).round() * 5.0;
                    
                    // Calcular el valor medio (mitad del rango)
                    final midValue = (baseMax - widget.minValue) / 2.0 + widget.minValue;
                    final distanceToMid = (roundedValue - midValue).abs();
                    
                    // Snap MUY fuerte al valor medio (tolerancia de 40 unidades y también por posición del slider)
                    double snappedValue;
                    final distanceToMidPosition = (value - 0.5).abs();
                    
                    // Si está cerca del medio tanto en valor como en posición del slider
                    if ((distanceToMid <= 40.0 || distanceToMidPosition <= 0.08) && roundedValue >= 50) {
                      // Si está cerca del medio, forzar al valor medio redondeado
                      snappedValue = (midValue / 5).round() * 5.0;
                    } else {
                      // Aplicar "snap" normal a valores que terminan en 00 o 50
                      snappedValue = _snapToRoundValues(roundedValue);
                    }
                    
                    // Permitir valores hasta el máximo + 1, pero mantener el valor seleccionado
                    double finalValue;
                    if (snappedValue > baseMax) {
                      // Permitir el valor máximo + 1, pero se mostrará en rojo
                      finalValue = snappedValue.clamp(widget.minValue, effectiveMax);
                    } else {
                      finalValue = snappedValue.clamp(widget.minValue, baseMax);
                    }
                    
                    // Actualizar el slider value basado en el valor final
                    final range = effectiveMax - widget.minValue;
                    final newSliderValue = range > 0 
                        ? ((finalValue - widget.minValue) / range).clamp(0.0, 1.0)
                        : 0.0;
                    
                    setState(() {
                      _sliderValue = newSliderValue;
                    });
                    widget.onChanged(finalValue);
                    
                    int intensity = (5 + (30 * value)).round();
                    Common().vibrate(20, intensity);
                  },
                  
                  min: 0.0,
                  max: 1.0,
                ),
              ),
              // Marcadores visuales para mitad y máximo
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SliderMarkersPainter(
                      midPosition: 0.5, // Mitad del slider
                      maxPosition: (baseMax - widget.minValue) / (effectiveMax - widget.minValue), // Posición del máximo permitido
                    ),
                  ),

                ),
              ),
              // Icono - en el extremo izquierdo (por encima del thumb)
              Positioned(
                left: 40,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _adjustValue(-5),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Icono + en el extremo derecho (por encima del thumb)
              Positioned(
                right: 40,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _adjustValue(5),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

// Pintor para los marcadores del slider
class _SliderMarkersPainter extends CustomPainter {
  final double midPosition;
  final double maxPosition;

  _SliderMarkersPainter({
    required this.midPosition,
    required this.maxPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Calcular posiciones
    final midX = size.width * midPosition;
    final centerY = size.height / 2;

    // Dibujar marcador de la mitad (solo un punto)
    if (midPosition > 0 && midPosition < 1) {
      // Solo un círculo/punto en la mitad
      canvas.drawCircle(
        Offset(midX, centerY),
        4,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BetAmountThumbShape extends SliderComponentShape {
  final ui.Image image;

  _BetAmountThumbShape({required this.image});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(70, 70);

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
    final thumbRect = Rect.fromCenter(center: center, width: 70.0, height: 70.0);
    final inner = thumbRect.deflate(8);

    paintImage(
      canvas: canvas,
      image: image,
      rect: inner,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}