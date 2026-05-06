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
  final bool circularThumb;
  final String fallbackAssetPath;

  const SlideToConfirm({
    super.key,
    required this.betAmount,
    this.transformedAmount,
    required this.icon,
    required this.onSlideComplete,
    this.scaleUp = false,
    this.transformThumb = false,
    this.disabled = false,
    this.circularThumb = false,
    this.fallbackAssetPath = 'assets/new_icon.png',
  });

  @override
  SlideToConfirmState createState() => SlideToConfirmState();
}

class SlideToConfirmState extends State<SlideToConfirm> {
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
      await _loadImageFromUrl(widget.icon);
    } else if (widget.icon != "null") {
      await _loadImageFromBase64(widget.icon);
    } else {
      await _loadSimpleLogoImage();
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('dollarCurrency') ?? false){
      _currency = 'usd';
    }
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _loadSimpleLogoImage() async {
    try {
      final data = await rootBundle.load(widget.fallbackAssetPath);
      final bytes = data.buffer.asUint8List();
      _thumbImage = await _decodeUiImage(bytes);
      if (mounted) setState(() {});
    } catch (_) {
      // Fallback final al icono histórico de la app si el asset configurable falla.
      final data = await rootBundle.load("assets/new_icon.png");
      final bytes = data.buffer.asUint8List();
      _thumbImage = await _decodeUiImage(bytes);
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        _thumbImage = await _decodeUiImage(bytes);
        if (mounted) setState(() {});
      } else {
        await _loadSimpleLogoImage();
      }
    } catch (_) {
      await _loadSimpleLogoImage();
    }
  }

  Future<void> _loadImageFromBase64(String base64String) async {
    try {
      final normalized = base64String
          .replaceFirst(RegExp(r'^data:image\/[a-zA-Z0-9.+-]+;base64,'), '')
          .replaceAll(RegExp(r'\s+'), '');
      final bytes = base64Decode(normalized);
      _thumbImage = await _decodeUiImage(bytes);
      if (mounted) setState(() {});
    } catch (_) {
      await _loadSimpleLogoImage();
    }
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
                      scaleUpIcon: widget.scaleUp,
                      circularClip: widget.circularThumb,
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
  final bool circularClip;

  _FadeThumbShape({
    required this.baseImage,
    this.transformImage,
    required this.transformProgress,
    required this.useFade,
    required this.scaleUpIcon,
    required this.circularClip,
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
    final circleRect = Rect.fromCircle(center: center, radius: inner.shortestSide / 2);

    if (circularClip) {
      canvas.save();
      canvas.clipPath(Path()..addOval(circleRect));
    }

    if (useFade && transformImage != null) {
      final t = transformProgress.clamp(0.0, 1.0);
      canvas.saveLayer(thumbRect, Paint());
      paintImage(
        canvas: canvas,
        image: baseImage,
        rect: circularClip ? circleRect : inner,
        fit: circularClip ? BoxFit.cover : BoxFit.contain,
        filterQuality: FilterQuality.high,
        opacity: 1.0 - t*1.1,
      );
      paintImage(
        canvas: canvas,
        image: transformImage!,
        rect: circularClip ? circleRect : inner,
        fit: circularClip ? BoxFit.cover : BoxFit.contain,
        filterQuality: FilterQuality.high,
        opacity: t*1.1,
      );
      canvas.restore();
    } else {
      paintImage(
        canvas: canvas,
        image: baseImage,
        rect: circularClip ? circleRect : inner,
        fit: circularClip ? BoxFit.cover : BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    if (circularClip) {
      canvas.restore();
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
    super.key,
    this.minValue = 0.0,
    this.maxValue = 5000.0,
    this.initialValue = 0.0,
    required this.onChanged,
    this.maxAllowedValue,
  });

  @override
  BetAmountSelectorState createState() => BetAmountSelectorState();
}

class BetAmountSelectorState extends State<BetAmountSelector> {
  late double _sliderValue;
  ui.Image? _thumbImage;

  Timer? _holdDelayTimer;
  Timer? _holdRepeatTimer;
  bool _holdRepeatActive = false;

  static const Duration _holdStepDelay = Duration(milliseconds: 420);
  static const Duration _holdStepInterval = Duration(milliseconds: 85);
  static const double _holdStepAmount = 100.0;

  @override
  void initState() {
    super.initState();
    _loadDefaultImage();
    _initializeSliderValue();
  }

  @override
  void dispose() {
    _cancelHoldTimers();
    super.dispose();
  }

  void _cancelHoldTimers() {
    _holdDelayTimer?.cancel();
    _holdDelayTimer = null;
    _holdRepeatTimer?.cancel();
    _holdRepeatTimer = null;
  }

  void _beginHoldRepeat(void Function() step) {
    _cancelHoldTimers();
    _holdRepeatActive = false;
    _holdDelayTimer = Timer(_holdStepDelay, () {
      if (!mounted) return;
      _holdRepeatActive = true;
      step();
      _holdRepeatTimer = Timer.periodic(_holdStepInterval, (_) {
        if (!mounted) return;
        step();
      });
    });
  }

  void _endHoldRepeat(void Function() singleTap) {
    _holdDelayTimer?.cancel();
    _holdDelayTimer = null;
    final didRepeat = _holdRepeatActive;
    _holdRepeatTimer?.cancel();
    _holdRepeatTimer = null;
    _holdRepeatActive = false;
    if (!didRepeat) singleTap();
  }

  /// Cancela temporizadores sin pulsar (p. ej. scroll que anula el tap).
  void _cancelHoldWithoutCommit() => _cancelHoldTimers();

  void _initializeSliderValue() {
    // El effectiveMax es el máximo permitido + 1 para mostrar el rango extendido
    final baseMax = widget.maxAllowedValue != null 
        ? (widget.maxAllowedValue! < widget.maxValue ? widget.maxAllowedValue! : widget.maxValue)
        : widget.maxValue;
    // Asegurar baseMax >= minValue (p. ej. cuando points < 5 y son decimales)
    final safeBaseMax = baseMax >= widget.minValue ? baseMax : widget.minValue;
    final effectiveMax = safeBaseMax + 1.0; // Añadir 1 al máximo para el rango extendido
    final range = effectiveMax - widget.minValue;
    
    if (range > 0 && safeBaseMax >= widget.minValue) {
      // Calcular el valor inicial: si máximo <= 19 paso 1, si no múltiplo de 10
      final quarterMax = safeBaseMax / 4.0;
      final roundedValue = safeBaseMax <= 19
          ? quarterMax.round().toDouble()
          : (quarterMax / 10.0).round() * 10.0;
      final initialValue = roundedValue.clamp(widget.minValue, safeBaseMax);
      
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(widget.minValue);
        }
      });
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

  /// Paso del selector: 1 si valor <= 19, si no 5.
  double _stepForValue(double value) {
    return value <= 19 ? 1.0 : 5.0;
  }

  /// Redondea al paso correcto según el valor (<=19 → entero, >=20 → múltiplo de 5).
  double _roundToStep(double value) {
    if (value <= 19) {
      return value.round().toDouble();
    }
    return (value / 5).round() * 5.0;
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
    final safeBaseMax = baseMax >= widget.minValue ? baseMax : widget.minValue;
    final effectiveMax = safeBaseMax + 1.0;
    final range = effectiveMax - widget.minValue;
    
    if (range <= 0) {
      widget.onChanged(widget.minValue);
      Common().vibrate(20, 30);
      return;
    }
    
    // Obtener el valor actual
    final currentValue = widget.minValue + (_sliderValue * range);
    final step = _stepForValue(currentValue);
    final actualDelta = delta > 0 ? step : -step;
    final newValue = (currentValue + actualDelta).clamp(widget.minValue, effectiveMax);
    final finalValue = _roundToStep(newValue).clamp(widget.minValue, effectiveMax);
    
    // Actualizar el slider value
    final newSliderValue = ((finalValue - widget.minValue) / range).clamp(0.0, 1.0);
    
    setState(() {
      _sliderValue = newSliderValue;
    });
    widget.onChanged(finalValue);
    Common().vibrate(20, 30);
  }

  /// Ajuste fijo (p. ej. ±100) al mantener pulsado + / −.
  void _adjustByFixedStep(double delta) {
    final baseMax = widget.maxAllowedValue != null
        ? (widget.maxAllowedValue! < widget.maxValue
            ? widget.maxAllowedValue!
            : widget.maxValue)
        : widget.maxValue;
    final safeBaseMax = baseMax >= widget.minValue ? baseMax : widget.minValue;
    final effectiveMax = safeBaseMax + 1.0;
    final range = effectiveMax - widget.minValue;

    if (range <= 0) {
      widget.onChanged(widget.minValue);
      Common().vibrate(20, 30);
      return;
    }

    final currentValue = widget.minValue + (_sliderValue * range);
    final newValue = (currentValue + delta).clamp(widget.minValue, effectiveMax);
    final newSliderValue =
        ((newValue - widget.minValue) / range).clamp(0.0, 1.0);

    setState(() {
      _sliderValue = newSliderValue;
    });
    widget.onChanged(newValue);
    Common().vibrate(18, 28);
  }

  /// Redondea el valor del slider (0..1) al paso válido para [divisions],
  /// para evitar "Invalid argument(s)" del Slider de Flutter.
  double _valueToValidDivision(double value, int divisions) {
    if (divisions <= 0) return value.clamp(0.0, 1.0);
    final step = 1.0 / divisions;
    final index = (value / step).round().clamp(0, divisions);
    return (index * step).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    // El effectiveMax es el máximo permitido + 1 para mostrar el rango extendido
    final baseMax = widget.maxAllowedValue != null 
        ? (widget.maxAllowedValue! < widget.maxValue ? widget.maxAllowedValue! : widget.maxValue)
        : widget.maxValue;
    final safeBaseMax = baseMax >= widget.minValue ? baseMax : widget.minValue;
    final effectiveMax = safeBaseMax + 1.0; // Añadir 1 al máximo para el rango extendido
    final range = effectiveMax - widget.minValue;

    int sliderDivisions(double baseMax, double effectiveMax) {
      final r = effectiveMax - widget.minValue;
      if (r <= 0) return 1;
      if (baseMax <= 19) {
        return r.round().clamp(1, 1000); // Paso 1
      }
      return (r / 5).round().clamp(1, 1000); // Paso 5
    }

    final divisions = sliderDivisions(safeBaseMax, effectiveMax);
    final clampedValue = _sliderValue.clamp(0.0, 1.0);
    final sliderValue = _valueToValidDivision(clampedValue, divisions);

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
                  divisions: divisions,
                  value: sliderValue,
                  onChanged: (value) {
                    final rangeForValue = effectiveMax - widget.minValue;
                    final rawValue = rangeForValue > 0
                        ? widget.minValue + (value * rangeForValue)
                        : widget.minValue;
                    // Paso 1 si <= 19, si no múltiplos de 5
                    final roundedValue = _roundToStep(rawValue);
                    
                    // Calcular el valor medio (mitad del rango)
                    final midValue = (safeBaseMax - widget.minValue) / 2.0 + widget.minValue;
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
                    if (snappedValue > safeBaseMax) {
                      // Permitir el valor máximo + 1, pero se mostrará en rojo
                      finalValue = snappedValue.clamp(widget.minValue, effectiveMax);
                    } else {
                      finalValue = snappedValue.clamp(widget.minValue, safeBaseMax);
                    }
                    
                    // Actualizar el slider value basado en el valor final
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
                      maxPosition: range > 0
                          ? (safeBaseMax - widget.minValue) / range
                          : 0.5,
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
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => _beginHoldRepeat(
                          () => _adjustByFixedStep(-_holdStepAmount)),
                      onTapUp: (_) =>
                          _endHoldRepeat(() => _adjustValue(-5)),
                      onTapCancel: _cancelHoldWithoutCommit,
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
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => _beginHoldRepeat(
                          () => _adjustByFixedStep(_holdStepAmount)),
                      onTapUp: (_) =>
                          _endHoldRepeat(() => _adjustValue(5)),
                      onTapCancel: _cancelHoldWithoutCommit,
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