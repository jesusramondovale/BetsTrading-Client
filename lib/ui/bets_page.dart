import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:betrader/Services/BetsService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/common.dart';
import '../helpers/slider.dart';
import '../models/rectangle_zone.dart';
import '../locale/localized_texts.dart';
import '../services/FirebaseService.dart';
import '../services/BetZoneRefresher.dart';
import 'layout_page.dart';


// Widget separado para la imagen de fondo que se construye solo una vez
class _BackgroundImage extends StatefulWidget {
  final String iconPath;
  final String name;

  const _BackgroundImage({
    required this.iconPath,
    required this.name,
  });

  @override
  _BackgroundImageState createState() => _BackgroundImageState();
}

class _BackgroundImageState extends State<_BackgroundImage> {
  Widget? _cachedImage;

  @override
  void initState() {
    super.initState();
    _buildImage();
  }

  void _buildImage() {
    if (widget.iconPath == "null") {
      _cachedImage = Image.asset(
        'assets/new_icon.png',
        fit: BoxFit.cover,
        cacheWidth: null,
        cacheHeight: null,
      );
    } else if (widget.iconPath.startsWith("http")) {
      _cachedImage = Image.network(
        widget.iconPath,
        fit: BoxFit.cover,
        cacheWidth: null,
        cacheHeight: null,
        errorBuilder: (context, error, StackTrace) =>
            Image.asset(
              "assets/new_icon.png",
              fit: BoxFit.cover,
            ),
      );
    } else {
      _cachedImage = Image.memory(
        base64Decode(widget.iconPath),
        fit: BoxFit.cover,
        cacheWidth: null,
        cacheHeight: null,
        errorBuilder: (context, error, stackTrace) =>
            Text(
              widget.name,
              maxLines: 1,
              style: GoogleFonts.roboto(
                  fontSize: 36, fontWeight: FontWeight.w100),
              textAlign: TextAlign.center,
            ),
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: _cachedImage ?? Image.asset(
        'assets/new_icon.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

class BetConfirmationPage extends StatefulWidget {
  final double currentValue;
  final String iconPath;
  final VoidCallback onCancel;
  final RectangleZone zone;
  final String name;

  const BetConfirmationPage({
    Key? key,
    required this.name,
    required this.onCancel,
    required this.zone,
    required this.currentValue,
    required this.iconPath,
  }) : super(key: key);

  @override
  _BetConfirmationPageState createState() => _BetConfirmationPageState();
}

class _BetConfirmationPageState extends State<BetConfirmationPage> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _points = '0.0';
  double _betAmount = 0.0;
  String _currency = 'eur';
  double _potentialPrize = 0.0;
  bool _isAcceptButtonEnabled = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  String _timeRemaining = '0h 0m 0s';
  bool _isBlocked = false;
  RectangleZone? _currentZone;
  late AnimationController _oddsAnimationController;
  late Animation<Color?> _oddsColorAnimation;

  // Calcula el mínimo de apuesta: 5 o el número de monedas del usuario si es menor
  double get _minBetAmount {
    final maxPoints = double.parse(_points ?? '0.0');
    return maxPoints < 5.0 ? maxPoints : 5.0;
  }
  Future<void> _loadPoints() async {
    _points = await _storage.read(key: 'points');
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('dollarCurrency') ?? false) {
      _currency = 'usd';
    }
    if (mounted) {
      setState(() {
        // Asegurar que _betAmount sea al menos el mínimo
        final minBet = _minBetAmount;
        if (_betAmount < minBet) {
          _betAmount = minBet;
        }
      });
    }
  }

  Future<void> _onAccept(int betZone) async {
    Common().vibrate();
    FocusScope.of(context).requestFocus(FocusNode());
    await Future.delayed(Duration(milliseconds: 100));
    final prefs = await SharedPreferences.getInstance();
    bool _bettingNotifications = prefs.getBool('bettingNotifications') ?? true;
    
    FocusScope.of(context).unfocus();

    bool? confirmed = await Common().popConfirmOperationDialog(context, _betAmount, widget.iconPath);
    if (confirmed == true) {
      String? userId = await _storage.read(key: 'sessionToken');      String fcm = FirebaseService().firebaseToken ?? "null";
      bool result = await BetsService().postNewBet(userId!, fcm, widget.zone.ticker, _betAmount, widget.currentValue, betZone, _currency.toUpperCase());
      
      if (result) {
        if (_bettingNotifications) {
          Common().showFloatingSnack(
              context,
              (LocalizedStrings.of(context)!.get('betPlacedSuccessfully') != null ?
              "${LocalizedStrings.of(context)!.get('betPlacedSuccessfully')} ${_betAmount.toStringAsFixed(2)} " : "Bet placed successfully! ${_betAmount} "),
              showIcon: true);
        }
        
        await BetsService().getUserInfo(userId);
        Navigator.pop(context);
        Navigator.pop(context);
        homeScreenKey.currentState?.loadUserIdAndData();
        exchangePageKey.currentState?.loadData();

      } else {
        if (_bettingNotifications) {
          Common().showFloatingSnack(
              context,
              (LocalizedStrings.of(context)!.get('errorMakingBet') ?? "Error creating bet!"),
              
              backgroundColor: Colors.red
          );
        }
        Navigator.pop(context);
        Navigator.pop(context);
      }
    }
  }

  void _handleAcceptPressed(int betZone) {
    Common().vibrate(200, 70);
    if (!_isAcceptButtonEnabled) {
      setState(() {});
    } else {
      _onAccept(betZone);
    }
  }

  void _onBetAmountChanged(double value) {
    setState(() {
      _betAmount = value;
      final zone = _currentZone ?? widget.zone;
      _potentialPrize = _betAmount * zone.odds;
      final maxPoints = double.parse(_points ?? '0.0');
      final minBet = _minBetAmount;
      // El botÃ³n estÃ¡ habilitado solo si el valor es vÃ¡lido (al menos el mÃnimo y no mayor al mÃ¡ximo permitido)
      // Permitir mÃ¡ximo + 1 pero mostrarlo en rojo (deshabilitado)
      // TambiÃ©n debe estar desbloqueado
      _isAcceptButtonEnabled =
          !_isBlocked &&
          _betAmount >= minBet &&
          _betAmount <= maxPoints &&
          _betAmount <= 5000.0;
    });
  }

  Widget _buildBetDetails(BuildContext context) {
    // Ya no necesitamos este widget, la informaciÃ³n estÃ¡ en el header
    return const SizedBox.shrink();
  }

  Widget _buildBetMultiplier(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final maxPoints = double.parse(_points ?? '0.0');
    // El tachado solo aparece cuando el valor es mayor al mÃ¡ximo permitido (mÃ¡ximo + 1)
    final shouldShowStrikethrough = _betAmount > maxPoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Text(
          strings?.get('betting') ?? 'Betting',
          style: GoogleFonts.montserrat(
            fontSize: 24.0,
            fontStyle: FontStyle.italic,
            color: Colors.white70,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _betAmount.toStringAsFixed(0),
              style: GoogleFonts.montserrat(
                fontSize: 36.0,
                fontWeight: FontWeight.w800,
                color: _isAcceptButtonEnabled ? Colors.white : Colors.red,
                decoration: shouldShowStrikethrough ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(width: 10),
            Image.asset(
              'assets/coin.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: BetAmountSelector(
            key: ValueKey(_points), // Forzar reconstrucciÃ³n cuando cambien los puntos
            minValue: _minBetAmount,
            maxValue: 5000.0,
            initialValue: _betAmount < _minBetAmount ? _minBetAmount : _betAmount,
            maxAllowedValue: _points != null ? double.tryParse(_points!) : null,
            onChanged: _onBetAmountChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings?.get('toWin') ?? 'To win: ',
                style: GoogleFonts.montserrat(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _potentialPrize.toStringAsFixed(2),
                style: GoogleFonts.montserrat(
                  fontSize: 26.0,
                  fontWeight: FontWeight.w800,
                  color: _isAcceptButtonEnabled ? const Color(0xFF2ECC71) : Colors.red,
                  decoration: shouldShowStrikethrough ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(width: 6),
              Image.asset(
                'assets/coin.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownTimer(BuildContext context) {
    final isExpired = _isBlocked || _timeRemaining == '0h0m0s';
    final strings = LocalizedStrings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isExpired 
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpired
                ? Colors.red.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              strings?.get('closesIn') ?? 'Closes in',
              style: GoogleFonts.montserrat(
                fontSize: 18.0,
                fontStyle: FontStyle.italic,
                color: isExpired ? Colors.red[300] : Colors.white70,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timeRemaining,
              style: GoogleFonts.montserrat(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: isExpired ? Colors.red[300] : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        child:
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: widget.onCancel,
            icon: Icon(CupertinoIcons.clear, color: Colors.black),
            label: Text(
              strings?.get('cancel') ?? 'Cancel',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isAcceptButtonEnabled
                ? () => _onAccept(widget.zone.id)
                : () => _handleAcceptPressed(widget.zone.id),
            icon: Icon(
              CupertinoIcons.check_mark,
              color: Colors.black,
            ),
            label: Text(
              strings?.get('accept') ?? 'Accept',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAcceptButtonEnabled ? Colors.green[300] : Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            ),
          ),
        ],
    ));
  }

  @override
  void initState() {
    super.initState();
    _currentZone = widget.zone;
    _loadPoints();
    _startCountdown();
    _startRefreshTimer();
    
    // Inicializar animación del odds
    _oddsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    
    // Animación que va de blanco -> amarillo -> blanco
    _oddsColorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.white,
          end: const Color(0xFFFFD700), // Amarillo dorado
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.4, // 30% del tiempo para ir a amarillo
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFFFD700), // Amarillo dorado
          end: Colors.white,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.5, // 70% del tiempo para volver a blanco
      ),
    ]).animate(_oddsAnimationController);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    _oddsAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateCountdown();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateCountdown() {
    final now = DateTime.now().toUtc();
    // Asegurar que las fechas estÃ©n en UTC para comparaciÃ³n correcta
    // Si ya estÃ¡n en UTC, no hacer conversiÃ³n (evita doble conversiÃ³n incorrecta)
    final rawStartDate = _currentZone?.startDate ?? widget.zone.startDate;
    final startDate = rawStartDate.isUtc ? rawStartDate : rawStartDate.toUtc();

    if (startDate.isBefore(now) || startDate.isAtSameMomentAs(now)) {
      if (mounted) {
        setState(() {
          _timeRemaining = '0h0m0s';
          _isBlocked = true;
          _isAcceptButtonEnabled = false;
        });
      }
      _countdownTimer?.cancel();
      _refreshTimer?.cancel();
      return;
    }

    final difference = startDate.difference(now);
    final totalSeconds = difference.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (mounted) {
      setState(() {
        _timeRemaining = '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
      });
    }
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!mounted || _isBlocked) {
        timer.cancel();
        return;
      }
      await _refreshZoneData();
    });
  }

  void _startOddsAnimation() {
    _oddsAnimationController.reset();
    _oddsAnimationController.forward();
  }


  Future<void> _refreshZoneData() async {
    if (_isBlocked || !mounted) return;
    
    try {
      final zones = await BetsService().fetchBetZones(
        widget.zone.ticker,
        TimeframeManager.current.value,
        null, // No hay betId porque estamos creando una nueva apuesta
        currency: _currency.toUpperCase(),
      );

      if (zones.isNotEmpty && mounted && !_isBlocked) {
        // Buscar la zona específica por ID
        final matchingZones = zones.where((zone) => zone.id == widget.zone.id).toList();

        if (matchingZones.isEmpty) {
          return;
        }
        final updatedZone = matchingZones.first;

        // Convertir BetZone a RectangleZone
        final rectangleZones = Common().getRectangleZonesFromBetZones(
          [updatedZone],
          widget.currentValue,
        );

        if (rectangleZones.isNotEmpty && mounted && !_isBlocked) {
          final newZone = rectangleZones.first;
          // Verificar si el odds realmente cambió
          final oldOdds = _currentZone?.odds ?? widget.zone.odds;
          final newOdds = newZone.odds;
          
          setState(() {
            _currentZone = newZone;
            // Actualizar el premio potencial si cambiÃ³ el odds
            _potentialPrize = _betAmount * newZone.odds;
          });
          
          // Iniciar animación en cada refresh automático (cada 15 segundos)
          _startOddsAnimation();
          
          // Debug: verificar si el odds cambió
          if (oldOdds != newOdds) {
            print("Odds actualizado: $oldOdds -> $newOdds");
          }
        }
      }
    } catch (e) {
      print("Error refreshing zone data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: _BackgroundImage(
                iconPath: widget.iconPath,
                name: widget.name,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter:
              ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Desenfoque
              child: Container(
                color: Colors.black.withValues(alpha:0.7),
              ),
            ),
          ),
          // Contenido de la pÃ¡gina
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBetHeader(context),
                      const SizedBox(height: 2),
                      _buildBetDetails(context),
                      _buildBetMultiplier(context),
                    ],
                  ),
                ),
              ),
              _buildCountdownTimer(context),
              _buildActionButtons(context),
            ],
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  Widget _buildBetHeader(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final zone = _currentZone ?? widget.zone;
    final String currencyChar = (_currency == 'eur' ? '€' : '\$');

    return Container(
      key: ValueKey('${zone.id}_${zone.odds}'), // Forzar reconstrucción cuando cambie el odds
      margin: const EdgeInsets.only(top: 80, left: 12, right: 12, bottom: 8),
      child: Column(
        children: [
          // Tarjeta principal con gradiente
          Container(
            height: 380,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: zone.type == 1 ? null : Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: zone.fillColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HSLColor.fromColor(zone.fillColor).withLightness(
                            (HSLColor.fromColor(zone.fillColor).lightness * 0.7).clamp(0.0, 1.0),
                          ).toColor().withValues(alpha: 0.35),
                          HSLColor.fromColor(zone.fillColor).withLightness(
                            (HSLColor.fromColor(zone.fillColor).lightness * 1.15).clamp(0.0, 1.0),
                          ).toColor().withValues(alpha: 0.35),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                    // PatrÃ³n decorativo de fondo
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ZonePatternPainter(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Ticker del activo
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Text(
                        zone.ticker.split('.')[0],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.syncopate(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    // Precio alto - mÃ¡s arriba
                    Positioned(
                      top: 70,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (strings?.get('alwaysBelow') ?? 'Always below').toUpperCase(),
                            style: GoogleFonts.figtree(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  FontAwesomeIcons.anglesDown,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatPrice(zone.highPrice, _currency == 'usd'),
                                style: GoogleFonts.figtree(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Odds gigante
                    Positioned(
                      top: 100,
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _oddsColorAnimation,
                          builder: (context, child) {
                            // Color blanco por defecto, amarillo solo durante la animación
                            final isAnimating = _oddsAnimationController.isAnimating;
                            final textColor = isAnimating 
                                ? (_oddsColorAnimation.value ?? Colors.white)
                                : Colors.white;
                            
                            return Text(
                              'x${zone.odds.toStringAsFixed(2)}',
                              key: ValueKey('odds_${zone.odds}'), // Forzar reconstrucción cuando cambie el odds
                              style: GoogleFonts.montserrat(
                                color: textColor,
                                fontSize: 54,
                                fontWeight: FontWeight.w300,
                                shadows: isAnimating
                                    ? [
                                        Shadow(
                                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                                          blurRadius: 20,
                                        ),
                                        Shadow(
                                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                          blurRadius: 40,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Precio bajo - mÃ¡s abajo
                    Positioned(
                      bottom: 70,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  FontAwesomeIcons.anglesUp,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatPrice(zone.lowPrice, _currency == 'usd'),
                                style: GoogleFonts.figtree(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (strings?.get('alwaysAbove') ?? 'Always above').toUpperCase(),
                            style: GoogleFonts.figtree(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tarjetas flotantes de informaciÃ³n
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildInfoBadge(
                        icon: Icons.trending_up,
                        label: strings?.get('originValue') ?? 'Origin',
                        value: '${widget.currentValue.toStringAsFixed(2)}$currencyChar',
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: _buildInfoBadge(
                        icon: FontAwesomeIcons.arrowsUpDown,
                        label: strings?.get('targetMargin') ?? 'Margin',
                        value: '${zone.margin.toStringAsFixed(2)}%',
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _buildInfoBadge(
                        icon: Icons.access_time,
                        label: strings?.get('duracion') ?? 'Duration',
                        value: '${zone.endDate.difference(zone.startDate).inHours} ${strings?.get('hours') ?? 'h'}',
                      ),
                    ),
                    // Etiqueta "DESDE" - izquierda, pegada al extremo, centrada verticalmente
                    Positioned(
                      left: 2,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Transform.rotate(
                          angle: 90 * 3.1415926535 / 180,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (strings?.get('from') ?? 'FROM'),
                              style: GoogleFonts.montserrat(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Fecha inicio - izquierda, pegada al extremo, centrada verticalmente
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Transform.rotate(
                          angle: 90 * 3.1415926535 / 180,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatDateShort(zone.startDate),
                                style: GoogleFonts.montserrat(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Fecha fin - derecha, pegada al extremo, centrada verticalmente
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Transform.rotate(
                          angle: -90 * 3.1415926535 / 180,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatDateShort(zone.endDate),
                                style: GoogleFonts.montserrat(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Etiqueta "HASTA" - derecha, pegada al extremo, centrada verticalmente
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Transform.rotate(
                          angle: -90 * 3.1415926535 / 180,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (strings?.get('until') ?? 'UNTIL'),
                              style: GoogleFonts.montserrat(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Powered by 12
                    Positioned(
                      top: 8,
                      right: -15,
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.only(right: 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'powered by',
                              style: GoogleFonts.montserrat(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Image.asset(
                              'assets/aws.png',
                              height: 30,
                              fit: BoxFit.fitHeight,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ],
                  ),
                  // Borde discontinuo cuando type == 1
                  if (zone.type == 1)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DashedBorderPainter(
                          borderColor: Colors.white.withValues(alpha: 0.9),
                          borderWidth: 2.5,
                          borderRadius: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.figtree(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(double value, bool dollarCurrency) {
    final thresholds = {
      5.0: 2,
      1.0: 3,
      0.1: 4,
      0.001: 5,
      0.000001: 8,
    };

    int decimals = 10;
    for (final entry in thresholds.entries) {
      if (value >= entry.key) {
        decimals = entry.value;
        break;
      }
    }

    String formatted = double.parse(value.toStringAsFixed(decimals)).toString();
    return "$formatted ${dollarCurrency ? '\$' : '€'}";
  }



  String _formatDateShort(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(date.day)}/${twoDigits(date.month)} ${twoDigits(date.hour)}:${twoDigits(date.minute)} UTC";
  }
}

// Pintor para el patrÃ³n decorativo de fondo
class _ZonePatternPainter extends CustomPainter {
  final Color color;

  _ZonePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Dibujar lÃ­neas diagonales sutiles
    for (int i = 0; i < 20; i++) {
      final y = (size.height / 20) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + size.width * 0.3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Pintor para el borde discontinuo
class _DashedBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  _DashedBorderPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
  });

  void _drawDashedRRect(
    Canvas canvas,
    RRect rrect,
    Paint paint, {
    double dashWidth = 5,
    double dashSpace = 3,
  }) {
    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        dashedPath.addPath(
          metric.extractPath(distance, next),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paintStroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    _drawDashedRRect(canvas, rrect, paintStroke, dashWidth: 6, dashSpace: 4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


