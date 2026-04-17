import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:betrader/services/bets_service.dart';
import 'package:betrader/services/mandatory_interstitial_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/common.dart';
import '../helpers/slider.dart';
import '../models/bet_zone.dart';
import '../models/rectangle_zone.dart';
import '../models/zone_type.dart';
import '../locale/localized_texts.dart';
import '../services/firebase_service.dart';
import '../services/secure_auth_service.dart';
import 'candlesticks_view.dart';
import 'layout_page.dart';


/// A widget that displays a background image for bet confirmation pages.
///
/// This widget handles different image sources (asset, network, or base64)
/// and caches the image widget to avoid rebuilding it unnecessarily.
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
        errorBuilder: (context, error, stackTrace) =>
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

/// A page that displays bet confirmation details and allows users to place bets.
///
/// This page shows the bet zone information, allows users to select a bet amount,
/// displays potential winnings, and provides countdown timer for bet expiration.
/// It also refreshes zone data periodically to keep odds updated.
class BetConfirmationPage extends StatefulWidget {
  /// The current price value of the asset.
  final double currentValue;
  
  /// The path to the asset icon (can be asset path, URL, or base64).
  final String iconPath;
  
  /// Optional callback when the user cancels (cancel uses Navigator.pop by default).
  final VoidCallback? onCancel;

  /// Controlador del menú principal (abre el gráfico en bottom sheet).
  final MainMenuPageController menuController;

  /// Marco temporal de la zona (1, 2, 4, 24 horas por vela).
  final int chartTimeframeHours;
  
  /// The bet zone containing price range and odds information.
  final RectangleZone zone;
  
  /// The name of the asset.
  final String name;

  /// True cuando se abre desde el tap en max_odds de diálogos trends/favs (solo un pop al cerrar).
  final bool fromDirectMaxOddFlow;

  const BetConfirmationPage({
    super.key,
    required this.name,
    this.onCancel,
    required this.menuController,
    required this.chartTimeframeHours,
    required this.zone,
    required this.currentValue,
    required this.iconPath,
    this.fromDirectMaxOddFlow = false,
  });

  @override
  BetConfirmationPageState createState() => BetConfirmationPageState();
}

class BetConfirmationPageState extends State<BetConfirmationPage> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final SecureAuthService _secureAuthService = SecureAuthService();
  String? _points = '0.0';
  double _betAmount = 0.0;
  String _currency = 'eur';
  double _potentialPrize = 0.0;
  bool _isAcceptButtonEnabled = false;
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  String _timeRemaining = '0h 0m 0s';
  bool _isBlocked = false;
  RectangleZone? _currentZone;
  late AnimationController _oddsAnimationController;
  Animation<Color?> _oddsColorAnimation = AlwaysStoppedAnimation<Color?>(Colors.white);
  
  // Color blanco constante del label (usado tanto inicial como final de la animación)
  static const Color _labelWhiteColor = Colors.white;

  /// Calculates the minimum bet amount.
  ///
  /// Returns 5 coins or the user's total points if less than 5.
  double get _minBetAmount {
    final maxPoints = double.parse(_points ?? '0.0');
    return maxPoints < 5.0 ? maxPoints : 5.0;
  }

  /// Maximum value for the bet selector. Ensures max >= min when points < 5
  /// (e.g. 4.45 points: floor is 4 but min is 4.45, so we use maxPoints so min never > max).
  double _maxBetValue(double maxPoints) {
    final floorMax = maxPoints.floor().toDouble();
    final minBet = _minBetAmount;
    return floorMax >= minBet ? floorMax : maxPoints;
  }

  /// Loads user points and currency preference from storage.
  ///
  /// Updates the bet amount to ensure it's at least the minimum required.
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

  /// Handles the bet acceptance process.
  ///
  /// Shows a confirmation dialog, posts the bet to the server, and navigates
  /// back if successful. Also refreshes user data and updates home/exchange pages.
  ///
  /// [betZone] The ID of the bet zone being accepted.
  Future<void> _onAccept(int betZone) async {
    Common().vibrate();
    FocusScope.of(context).requestFocus(FocusNode());
    await Future.delayed(Duration(milliseconds: 100));
    final prefs = await SharedPreferences.getInstance();
    bool bettingNotifications = prefs.getBool('bettingNotifications') ?? true;
    
    FocusScope.of(context).unfocus();

    bool? confirmed = await Common().popConfirmOperationDialog(context, _betAmount, widget.iconPath);
    if (confirmed == true) {
      String? userId = await _storage.read(key: 'sessionToken');
      String fcm = FirebaseService().firebaseToken ?? "null";
      String password = "";
      String stepUpToken = "";
      if (_betAmount >= 1000) {
        final biometricEnabled = await _secureAuthService.isBiometricEnabled();
        if (biometricEnabled) {
          final token = await _secureAuthService.runStepUpWithBiometric(
            context,
            purpose: 'bet',
            maxAmountCoins: _betAmount,
          );
          if (token == null) return;
          stepUpToken = token;
        } else {
          final entered = await _secureAuthService.promptPasswordDialog(context);
          if (entered == null || entered.isEmpty) return;
          password = entered;
        }
      }

      bool result = await BetsService().postNewBet(
        userId!,
        fcm,
        widget.zone.ticker,
        _betAmount,
        widget.currentValue,
        betZone,
        _currency.toUpperCase(),
        password: password,
        stepUpToken: stepUpToken,
      );
      
      if (result) {
        if (bettingNotifications) {
          Common().showFloatingSnack(
              context,
              (LocalizedStrings.of(context)!.get('betPlacedSuccessfully') != null ?
              "${LocalizedStrings.of(context)!.get('betPlacedSuccessfully')} ${_betAmount.toStringAsFixed(2)} " : "Bet placed successfully! $_betAmount "),
              showIcon: true);
        }
        
        await BetsService().getUserInfo(userId);
        Navigator.pop(context);
        if (!widget.fromDirectMaxOddFlow) {
          Navigator.pop(context);
        }

        homeScreenKey.currentState?.loadUserIdAndData();
        exchangePageKey.currentState?.loadData();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future<void>.delayed(const Duration(milliseconds: 600), () {
            MandatoryInterstitialService.instance
                .requestShow(MandatoryInterstitialReason.bet);
          });
        });

      } else {
        if (bettingNotifications) {
          Common().showFloatingSnack(
              context,
              (LocalizedStrings.of(context)!.get('errorMakingBet') ?? "Error creating bet!"),
              
              backgroundColor: Colors.red
          );
        }
        Navigator.pop(context);
        if (!widget.fromDirectMaxOddFlow) {
          Navigator.pop(context);
        }
      }
    }
  }

  /// Handles the accept button press event.
  ///
  /// Provides haptic feedback and either triggers bet acceptance or shows
  /// an error state if the bet cannot be placed.
  ///
  /// [betZone] The ID of the bet zone.
  void _handleAcceptPressed(int betZone) {
    Common().vibrate(200, 70);
    if (!_isAcceptButtonEnabled) {
      setState(() {});
    } else {
      _onAccept(betZone);
    }
  }

  /// Called when the bet amount changes.
  ///
  /// Updates the bet amount, recalculates potential prize, and enables/disables
  /// the accept button based on validation rules.
  ///
  /// [value] The new bet amount value.
  void _onBetAmountChanged(double value) {
    setState(() {
      _betAmount = value;
      final zone = _currentZone ?? widget.zone;
      _potentialPrize = _betAmount * zone.odds;
      final maxPoints = double.parse(_points ?? '0.0');
      final minBet = _minBetAmount;
      // El boton esta habilitado solo si el valor es valido (al menos el minimo y no mayor al maximo permitido)
      // Permitir maximo + 1 pero mostrarlo en rojo (deshabilitado)
      // Tambien debe estar desbloqueado
      _isAcceptButtonEnabled =
          !_isBlocked &&
          _betAmount >= minBet &&
          _betAmount <= maxPoints;
    });
  }

  Widget _buildBetDetails(BuildContext context) {
    // Ya no necesitamos este widget, la informacion esta en el header
    return const SizedBox.shrink();
  }

  Widget _buildBetMultiplier(BuildContext context, BoxConstraints constraints) {
    final strings = LocalizedStrings.of(context);
    final maxPoints = double.parse(_points ?? '0.0');
    // El tachado solo aparece cuando el valor es mayor al maximo permitido (maximo + 1)
    final shouldShowStrikethrough = _betAmount > maxPoints;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final scaleFactor = (screenHeight / 800.0).clamp(0.75, 1.2);


    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: (1 * scaleFactor).clamp(4.0, 12.0)),
        Text(
          strings?.get('betting') ?? 'Betting',
          style: GoogleFonts.montserrat(
            fontSize: (20.0 * scaleFactor).clamp(16.0, 24.0),
            fontStyle: FontStyle.italic,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: (4 * scaleFactor).clamp(2.0, 8.0)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _betAmount.toStringAsFixed(0),
              style: GoogleFonts.montserrat(
                fontSize: (32.0 * scaleFactor).clamp(24.0, 36.0),
                fontWeight: FontWeight.w800,
                color: _isAcceptButtonEnabled ? Colors.white : Colors.red,
                decoration: shouldShowStrikethrough ? TextDecoration.lineThrough : null,
              ),
            ),
            SizedBox(width: (8 * scaleFactor).clamp(4.0, 10.0)),
            Image.asset(
              'assets/coin.png',
              width: (32 * scaleFactor).clamp(24.0, 36.0),
              height: (32 * scaleFactor).clamp(24.0, 36.0),
              fit: BoxFit.contain,
            ),
          ],
        ),
        SizedBox(height: (4 * scaleFactor).clamp(2.0, 8.0)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: (20.0 * scaleFactor).clamp(12.0, 24.0)),
          child: BetAmountSelector(
            key: ValueKey(_points), // Forzar reconstruccion cuando cambien los puntos
            minValue: _minBetAmount,
            maxValue: _maxBetValue(maxPoints),
            initialValue: _betAmount < _minBetAmount ? _minBetAmount : _betAmount,
            maxAllowedValue: _points != null ? double.tryParse(_points!) : null,
            onChanged: _onBetAmountChanged,
          ),
        ),
        SizedBox(height: (4 * scaleFactor).clamp(2.0, 8.0)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: (10.0 * scaleFactor).clamp(6.0, 14.0)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings?.get('toWin') ?? 'To win: ',
                style: GoogleFonts.montserrat(
                  fontSize: (18.0 * scaleFactor).clamp(14.0, 20.0),
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              SizedBox(width: (10 * scaleFactor).clamp(6.0, 14.0)),
              Text(
                _potentialPrize.toStringAsFixed(2),
                style: GoogleFonts.montserrat(
                  fontSize: (24.0 * scaleFactor).clamp(18.0, 28.0),
                  fontWeight: FontWeight.w800,
                  color: _isAcceptButtonEnabled ? const Color(0xFF2ECC71) : Colors.red,
                  decoration: shouldShowStrikethrough ? TextDecoration.lineThrough : null,
                ),
              ),
              SizedBox(width: (6 * scaleFactor).clamp(4.0, 8.0)),
              Image.asset(
                'assets/coin.png',
                width: (20 * scaleFactor).clamp(16.0, 24.0),
                height: (20 * scaleFactor).clamp(16.0, 24.0),
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

  void _openTickerChart(BuildContext context) {
    Common().vibrate();
    Common().applyImmersive();
    final tf = widget.chartTimeframeHours;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (BuildContext ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.56,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: MediaQuery.of(ctx).size.height,
              child: Column(
                children: [
                  Expanded(
                    child: CandlesticksView(
                      ticker: widget.zone.ticker,
                      name: widget.name,
                      controller: widget.menuController,
                      iconPath: widget.iconPath,
                      initialTimeframeHours: tf,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static const double _actionButtonHeight = 50.0;
  static const double _actionButtonRadius = 20.0;

  Widget _buildElongatedIconAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(_actionButtonRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(_actionButtonRadius),
          onTap: onPressed,
          child: SizedBox(
            height: _actionButtonHeight,
            width: double.infinity,
            child: Icon(icon, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildElongatedIconAction(
                    tooltip: strings?.get('cancel') ?? 'Cancel',
                    icon: CupertinoIcons.clear,
                    onPressed: () {
                      Common().vibrate();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildElongatedIconAction(
                    tooltip: strings?.get('viewChart') ?? 'View chart',
                    icon: CupertinoIcons.chart_bar_alt_fill,
                    onPressed: () => _openTickerChart(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                minimumSize: const Size(double.infinity, _actionButtonHeight),
                maximumSize: const Size(double.infinity, _actionButtonHeight),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_actionButtonRadius),
                ),
              ),
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
    // Duración total: 0.1s (ir al color) + 1.5s (mantener) + 1s (desvanecer) = 2.6s
    _oddsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );
    
    // Animación inicial (se actualizará dinámicamente según el cambio del odds)
    _oddsColorAnimation = AlwaysStoppedAnimation<Color?>(_labelWhiteColor);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    _oddsAnimationController.dispose();
    super.dispose();
  }

  /// Starts the countdown timer that updates every second.
  ///
  /// The timer shows remaining time until the bet zone closes and automatically
  /// blocks betting when the time expires.
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

  /// Updates the countdown display with remaining time until bet zone closes.
  ///
  /// Formats the time as hours, minutes, and seconds. Blocks betting if time expires.
  void _updateCountdown() {
    final now = DateTime.now().toUtc();
    // Asegurar que las fechas estan en UTC para comparacion correcta
    // Si ya estan en UTC, no hacer conversion (evita doble conversion incorrecta)
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

  /// Starts a periodic timer to refresh bet zone data every 5 seconds.
  ///
  /// This keeps the odds and zone information up to date while the user
  /// is viewing the bet confirmation page.
  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || _isBlocked) {
        timer.cancel();
        return;
      }
      await _refreshZoneData();
    });
  }

  /// Starts an animation when odds change.
  ///
  /// Creates a color animation sequence: quickly transitions to the animation color,
  /// holds it for 1.5 seconds, then fades back to white.
  ///
  /// [animationColor] The color to animate to (green for increase, red for decrease).
  void _startOddsAnimation({required Color animationColor}) {
    // Crear animación dinámica: blanco -> color (rápido) -> mantener color (1.5s) -> blanco (desvanecer lentamente)
    // Usar _labelWhiteColor para asegurar que el blanco final sea exactamente el mismo que el inicial
    _oddsColorAnimation = TweenSequence<Color?>([
      // Fase 1: Ir al color rápidamente (0.1s)
      TweenSequenceItem(
        tween: ColorTween(
          begin: _labelWhiteColor,
          end: animationColor,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.1, // ~4% del tiempo total (0.1s de 2.6s)
      ),
      // Fase 2: Mantener el color (1.5s)
      TweenSequenceItem(
        tween: ColorTween(
          begin: animationColor,
          end: animationColor,
        ),
        weight: 1.5, // ~58% del tiempo total (1.5s de 2.6s)
      ),
      // Fase 3: Desvanecer lentamente a blanco (1s) - usando el mismo blanco del label
      TweenSequenceItem(
        tween: ColorTween(
          begin: animationColor,
          end: _labelWhiteColor,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1.0, // ~38% del tiempo total (1s de 2.6s)
      ),
    ]).animate(_oddsAnimationController);
    
    _oddsAnimationController.reset();
    _oddsAnimationController.forward();
  }


  /// Refreshes the bet zone data from the server.
  ///
  /// Fetches updated zone information, recalculates potential prize if odds changed,
  /// and triggers visual feedback animations for odds changes.
  Future<void> _refreshZoneData() async {
    if (_isBlocked || !mounted) return;
    
    try {
      final List<BetZone> zones = await BetsService().fetchBetZones(
        widget.zone.ticker,
        widget.chartTimeframeHours,
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
          final updatedZone = rectangleZones.first;
          // Verificar si el odds realmente cambió
          final oldOdds = _currentZone?.odds ?? widget.zone.odds;
          final newOdds = updatedZone.odds;
          
          // Preservar el fillColor original de la zona inicial para evitar cambios de color
          final originalFillColor = _currentZone?.fillColor ?? widget.zone.fillColor;
          
          // Crear una nueva instancia con el fillColor preservado pero con los datos actualizados
          final newZone = RectangleZone(
            id: updatedZone.id,
            startDate: updatedZone.startDate,
            endDate: updatedZone.endDate,
            highPrice: updatedZone.highPrice,
            lowPrice: updatedZone.lowPrice,
            margin: updatedZone.margin,
            fillColor: originalFillColor, // Preservar el color original
            strokeColor: updatedZone.strokeColor,
            odds: updatedZone.odds,
            ticker: updatedZone.ticker,
            zoneType: updatedZone.zoneType,
          );
          
          setState(() {
            _currentZone = newZone;
            // Actualizar el premio potencial si cambio el odds
            _potentialPrize = _betAmount * newZone.odds;
          });
          
          // Iniciar animación con color según si el odds aumentó o disminuyó
          if (oldOdds != newOdds) {
            final animationColor = newOdds > oldOdds 
                ? const Color(0xFF2ECC71) // Verde si aumentó
                : const Color(0xFFE74C3C); // Rojo si disminuyó
            _startOddsAnimation(animationColor: animationColor);
            if (kDebugMode) {
              print("Odds actualizado: $oldOdds -> $newOdds (${newOdds > oldOdds ? 'aumentó' : 'disminuyó'})");
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error refreshing zone data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      extendBody: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
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
              // Contenido de la pagina
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenHeight * 0.005,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              flex: 3,
                              child: _buildBetHeader(context, constraints),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            _buildBetDetails(context),
                            Spacer(),
                            Flexible(
                              flex: 2,
                              child: _buildBetMultiplier(context, constraints),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildCountdownTimer(context),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  Widget _buildBetHeader(BuildContext context, BoxConstraints constraints) {
    final strings = LocalizedStrings.of(context);
    final zone = _currentZone ?? widget.zone;
    final String currencyChar = (_currency == 'eur' ? '€' : '\$');
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    
    // Factor de escala basado en la altura de pantalla (normalizado a 800px)
    final scaleFactor = (screenHeight / 800.0).clamp(0.75, 1.2);
    
    // Márgenes y tamaños escalados
    final topMargin = (screenHeight * 0.02).clamp(10.0, 20.0);
    final horizontalMargin = (screenWidth * 0.03).clamp(8.0, 16.0);
    
    // Calcular altura máxima disponible: altura total menos SafeArea y componentes fijos
    final safeAreaTop = mediaQuery.padding.top;
    final safeAreaBottom = mediaQuery.padding.bottom;
    final countdownTimerHeight = 74.0; // padding 12*2 + contenido ~50
    final actionButtonsHeight = 86.0; // padding 18*2 + botones ~50
    final sliderAndContentHeight = 220.0; // Altura aproximada del slider y contenido del BetMultiplier
    
    // Altura disponible para el Expanded = pantalla - SafeArea - componentes fijos
    final expandedHeight = screenHeight - safeAreaTop - safeAreaBottom - countdownTimerHeight - actionButtonsHeight;
    
    // Calcular altura del header: usar un porcentaje del espacio disponible (65%)
    // pero asegurando que quede espacio suficiente para el slider debajo (mínimo 220px).
    // En pantallas pequeñas o con poco espacio permitir header más bajo para evitar overflow.
    const double minHeaderHeight = 220.0;
    final calculatedHeight = expandedHeight * 0.65;
    final maxHeaderHeight = expandedHeight - sliderAndContentHeight - topMargin - (screenHeight * 0.01);
    final headerHeight = calculatedHeight.clamp(minHeaderHeight, maxHeaderHeight.clamp(minHeaderHeight, 520.0));

    return Container(
      
      key: ValueKey('${zone.id}'), // Usar solo el ID para evitar reconstrucciones innecesarias
      margin: EdgeInsets.only(
        top: topMargin,
        left: horizontalMargin,
        right: horizontalMargin,
        bottom: screenHeight * 0.01,
      ),
      child: Column(
        children: [
          // Tarjeta principal con gradiente
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: headerHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HSLColor.fromColor(zone.fillColor).withLightness(
                            (HSLColor.fromColor(zone.fillColor).lightness * 0.7).clamp(0.0, 1.0),
                          ).toColor().withValues(alpha: 0.55),
                          HSLColor.fromColor(zone.fillColor).withLightness(
                            (HSLColor.fromColor(zone.fillColor).lightness * 1.15).clamp(0.0, 1.0),
                          ).toColor().withValues(alpha: 0.55),
                        ],
                        
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                    // Patron decorativo de fondo
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ZonePatternPainter(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Ticker del activo
                    Positioned(
                      top: headerHeight * 0.05,
                      left: 0,
                      right: 0,
                      child: Text(
                        zone.ticker.split('.')[0],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.syncopate(
                          color: Colors.white,
                          fontSize: (28 * scaleFactor).clamp(20.0, 32.0),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2 * scaleFactor,
                        ),
                      ),
                    ),
                    // Precio alto - mas arriba
                    Positioned(
                      top: headerHeight * 0.18,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (() {
                              if (zone.zoneType == BetZoneType.extreme) {
                                return (strings?.get('aboveShort') ?? 'Above').toUpperCase();
                              }
                              if (zone.zoneType == BetZoneType.limit) {
                                final isUpperLimit = zone.lowPrice > widget.currentValue;
                                if (!isUpperLimit) {
                                  // Límite inferior: el borde superior es discontinuo.
                                  return (strings?.get('aboveShort') ?? 'Above').toUpperCase();
                                }
                              }
                              return (strings?.get('alwaysBelow') ?? 'Always below').toUpperCase();
                            })(),
                            style: GoogleFonts.figtree(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: (16 * scaleFactor).clamp(12.0, 18.0),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 4 * scaleFactor),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(6 * scaleFactor),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  FontAwesomeIcons.anglesDown,
                                  size: (14 * scaleFactor).clamp(10.0, 16.0),
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8 * scaleFactor),
                              Text(
                                _formatPrice(zone.highPrice, _currency == 'usd'),
                                style: GoogleFonts.figtree(
                                  color: Colors.white,
                                  fontSize: (20 * scaleFactor).clamp(16.0, 24.0),
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
                      top: headerHeight * 0.26,
                      bottom: headerHeight * 0.26,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _oddsColorAnimation,
                          builder: (context, child) {
                            // Color blanco por defecto, color animado durante la animación
                            final isAnimating = _oddsAnimationController.isAnimating;
                            final currentColor = _oddsColorAnimation.value ?? _labelWhiteColor;
                            // Usar siempre el color de la animación o el blanco del label (mismo valor)
                            final textColor = isAnimating 
                                ? currentColor
                                : _labelWhiteColor; // Color normal del label (mismo que el final del easeOut)
            
                            // Las sombras solo aparecen cuando el color no es blanco (durante la animación)
                            // Se desvanecen gradualmente cuando el color vuelve a blanco
                            final shadowColor = isAnimating && currentColor != _labelWhiteColor 
                                ? currentColor 
                                : null;
                            
                            return Text(
                              'x${zone.odds.toStringAsFixed(2)}',
                              key: ValueKey('odds_${zone.odds}'), // Forzar reconstrucción cuando cambie el odds
                              style: GoogleFonts.montserrat(
                                color: textColor,
                                // −20% respecto a (54*scale).clamp(40,64); alivia overflow en pantallas bajas
                                fontSize: ((54 * scaleFactor).clamp(40.0, 64.0)) * 0.8,
                                fontWeight: FontWeight.w300,
                                shadows: shadowColor != null
                                    ? [
                                        Shadow(
                                          color: shadowColor.withValues(alpha: 0.5),
                                          blurRadius: 20,
                                        ),
                                        Shadow(
                                          color: shadowColor.withValues(alpha: 0.3),
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
                    // Precio bajo - mas abajo
                    Positioned(
                      bottom: headerHeight * 0.18,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(6 * scaleFactor),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  FontAwesomeIcons.anglesUp,
                                  size: (14 * scaleFactor).clamp(10.0, 16.0),
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8 * scaleFactor),
                              Text(
                                _formatPrice(zone.lowPrice, _currency == 'usd'),
                                style: GoogleFonts.figtree(
                                  color: Colors.white,
                                  fontSize: (20 * scaleFactor).clamp(16.0, 24.0),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4 * scaleFactor),
                          Text(
                            (() {
                              if (zone.zoneType == BetZoneType.extreme) {
                                return (strings?.get('belowShort') ?? 'Below').toUpperCase();
                              }
                              if (zone.zoneType == BetZoneType.limit) {
                                final isUpperLimit = zone.lowPrice > widget.currentValue;
                                if (isUpperLimit) {
                                  // Límite superior: el borde inferior es discontinuo.
                                  return (strings?.get('belowShort') ?? 'Below').toUpperCase();
                                }
                              }
                              return (strings?.get('alwaysAbove') ?? 'Always above').toUpperCase();
                            })(),
                            style: GoogleFonts.figtree(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: (16 * scaleFactor).clamp(12.0, 18.0),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tarjetas flotantes de informacion
                    Positioned(
                      top: 8 * scaleFactor,
                      left: 8 * scaleFactor,
                      child: _buildInfoBadge(
                        label: strings?.get('originValue') ?? 'Origin',
                        value: '${widget.currentValue.toStringAsFixed(2)}$currencyChar',
                        scaleFactor: scaleFactor,
                      ),
                    ),
                    Positioned(
                      bottom: 8 * scaleFactor,
                      left: 8 * scaleFactor,
                      child: _buildInfoBadge(
                        icon: FontAwesomeIcons.arrowsUpDown,
                        label: strings?.get('targetMargin') ?? 'Margin',
                        value: '${zone.margin.toStringAsFixed(2)}%',
                        scaleFactor: scaleFactor,
                      ),
                    ),
                    Positioned(
                      bottom: 8 * scaleFactor,
                      right: 8 * scaleFactor,
                      child: _buildInfoBadge(
                        icon: Icons.access_time,
                        label: strings?.get('duracion') ?? 'Duration',
                        value: '${zone.endDate.difference(zone.startDate).inHours} ${strings?.get('hours') ?? 'h'}',
                        scaleFactor: scaleFactor,
                      ),
                    ),
                    // Etiqueta "DESDE" - izquierda, pegada al extremo, centrada verticalmente
                    Positioned(
                      left: -10,
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    // Fecha fin - derecha, pegada al extremo, centrada verticalmente
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
                    // Etiqueta "HASTA" - derecha, pegada al extremo, centrada verticalmente
                    Positioned(
                      right: -10,
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
                    // Powered by AWS
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
                              height: 25,
                              fit: BoxFit.fitHeight,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ],
                  ),
                  if (zone.zoneType == BetZoneType.standard)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SolidBorderPainter(
                          borderColor: Colors.white.withValues(alpha: 0.9),
                          borderWidth: 1.0,
                          borderRadius: 20,
                        ),
                      ),
                    ),
                  if (zone.zoneType == BetZoneType.extreme)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DashedFullBorderPainter(
                          borderColor: Colors.white.withValues(alpha: 0.9),
                          borderWidth: 1.0,
                          borderRadius: 20,
                        ),
                      ),
                    ),
                  if (zone.zoneType == BetZoneType.limit)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LimitBorderPainter(
                          borderColor: Colors.white.withValues(alpha: 0.9),
                          borderWidth: 1.2,
                          borderRadius: 20,
                          isUpperLimit: zone.lowPrice > widget.currentValue,
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
    IconData? icon,
    required String label,
    required String value,
    double scaleFactor = 1.0,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (10 * scaleFactor).clamp(6.0, 12.0),
        vertical: (8 * scaleFactor).clamp(4.0, 10.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12 * scaleFactor),
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
          if (icon != null) ...
          [
            Icon(icon, size: (14 * scaleFactor).clamp(10.0, 16.0), color: Colors.white)
          ],
          SizedBox(width: (6 * scaleFactor).clamp(4.0, 8.0)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: (10 * scaleFactor).clamp(7.0, 11.0),
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.figtree(
                  color: Colors.white,
                  fontSize: (14 * scaleFactor).clamp(11.0, 16.0),
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

/// A custom painter that draws a decorative diagonal line pattern for bet zones.
class _ZonePatternPainter extends CustomPainter {
  final Color color;

  _ZonePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Dibujar lineas diagonales sutiles
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

class _SolidBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  _SolidBorderPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paintStroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paintStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LimitBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final bool isUpperLimit;

  _LimitBorderPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.isUpperLimit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final linePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + 6;
        dashedPath.addPath(metric.extractPath(distance, next), Offset.zero);
        distance += 10;
      }
    }
    canvas.drawPath(dashedPath, linePaint);

    final rx = rrect.tlRadiusX;
    final ry = rrect.tlRadiusY;
    final limitPath = Path();

    if (isUpperLimit) {
      final tlRect = Rect.fromLTWH(rrect.left, rrect.top, rx * 2, ry * 2);
      final trRect = Rect.fromLTWH(rrect.right - rx * 2, rrect.top, rx * 2, ry * 2);
      limitPath.moveTo(rrect.left, rrect.top + ry);
      limitPath.addArc(tlRect, math.pi, math.pi / 2);
      limitPath.lineTo(rrect.right - rx, rrect.top);
      limitPath.addArc(trRect, -math.pi / 2, math.pi / 2);
      limitPath.lineTo(rrect.right, rrect.top + ry);
    } else {
      final blRect = Rect.fromLTWH(rrect.left, rrect.bottom - ry * 2, rx * 2, ry * 2);
      final brRect = Rect.fromLTWH(rrect.right - rx * 2, rrect.bottom - ry * 2, rx * 2, ry * 2);
      limitPath.moveTo(rrect.left, rrect.bottom - ry);
      limitPath.addArc(blRect, math.pi, -math.pi / 2);
      limitPath.lineTo(rrect.right - rx, rrect.bottom);
      limitPath.addArc(brRect, math.pi / 2, -math.pi / 2);
      limitPath.lineTo(rrect.right, rrect.bottom - ry);
    }

    canvas.drawPath(limitPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LimitBorderPainter oldDelegate) =>
      oldDelegate.isUpperLimit != isUpperLimit ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.borderRadius != borderRadius;
}

class _DashedFullBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  _DashedFullBorderPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..isAntiAlias = true;

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + 5;
        dashedPath.addPath(metric.extractPath(distance, next), Offset.zero);
        distance += 8;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedFullBorderPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.borderRadius != borderRadius;
}


