import 'package:betrader/candlesticks/candlesticks.dart';
import 'package:betrader/models/betZone.dart';
import 'package:betrader/services/BetsService.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../helpers/common.dart';
import '../models/bets.dart';
import '../models/rectangle_zone.dart';
import '../services/BetZoneRefresher.dart';
import 'layout_page.dart';

class CandlesticksView extends StatefulWidget {
  final String ticker;
  final String name;
  final String iconPath;
  final MainMenuPageController controller;
  final int? betId;
  final bool tutorialMode;

  CandlesticksView({
    super.key,
    required this.controller,
    required this.iconPath,
    required this.ticker,
    this.betId,
    required this.name,
    this.tutorialMode = false
  });

  @override
  CandlesticksViewState createState() => CandlesticksViewState();
}

class CandlesticksViewState extends State<CandlesticksView> {
  final ValueNotifier<double> candleScaleNotifier = ValueNotifier<double>(1.0);
  final ValueNotifier<List<RectangleZone>> _zonesNotifier = ValueNotifier([]);
  late ValueNotifier<List<RectangleZone>> _frozenZonesNotifier = ValueNotifier([]);

  late final List<RectangleZone> _initialZones;
  List<Candle> _candles = [];
  bool _isLoading = true;
  late bool _inactive_zone;
  late int _extraHours;
  int _finishedIcon = 0;

  // --------- TUTORIAL: flags/keys/coach ---------
  static const _PENDING_FLAG = '__tutorial_pending__candles_v1';
  static const _SEEN_FLAG    = '__tutorial_seen__candles_v1';

  final _kChart = GlobalKey();
  final _kBack  = GlobalKey();
  final _kZoom = GlobalKey();
  final _kExactPrice = GlobalKey();
  final _kTimeframe = GlobalKey();
  TutorialCoachMark? _coach;
  bool _started = false;
  // ----------------------------------------------

  Future<void> _loadData() async {
    try {
      final List<Candle> candles;
      final List<BetZone> betZones = await BetsService().fetchBetZones(
          widget.ticker,
          TimeframeManager.current.value,
          widget.betId
      );

      int finishedIcon = 0;
      if (_inactive_zone){
        final Bet? theBet = await BetsService().fetchBet(widget.betId.toString());
        if (theBet != null) {
          if (theBet.finished == true && theBet.targetWon == true) {
            finishedIcon = 1;
          } else if (theBet.finished == true && theBet.targetWon == false) {
            finishedIcon = -1;
          }
        }
      }

      candles = await BetsService().fetchCandles(widget.ticker, TimeframeManager.current.value);
      List<RectangleZone> rectangleZones = Common()
          .getRectangleZonesFromBetZones(
          betZones, candles.isNotEmpty ? candles.first.close : 0.0);
      _initialZones = rectangleZones;
      _frozenZonesNotifier = ValueNotifier(_initialZones);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!_inactive_zone) {
          _zonesNotifier.value = _initialZones;
          _finishedIcon = 0;
        } else {
          _finishedIcon = finishedIcon;
        }
        _candles = candles;
      });

      // intenta arrancar tutorial tras datos cargados
      _maybeStartTutorial();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // aunque falle la carga, intenta tutorial por si al menos se renderiza algo
      _maybeStartTutorial();
    }
  }

  @override
  void initState() {
    super.initState();
    TimeframeManager.set(1);
    _inactive_zone = widget.betId != null;
    _extraHours = Common().hoursUntilLatestEndDate(
        _inactive_zone ? _frozenZonesNotifier.value : _zonesNotifier.value,
        _candles.isNotEmpty ? _candles.first.date : DateTime.now().toUtc(),
        TimeframeManager.current.value) + 1;

    _zonesNotifier.addListener(() {
      if (!_inactive_zone) {
        int newExtraHours = Common().hoursUntilLatestEndDate(
            _zonesNotifier.value,
            _candles.isNotEmpty ? _candles.first.date : DateTime.now().toUtc(),
            TimeframeManager.current.value
        );
        if (_extraHours != newExtraHours){
          if (!mounted) return;
          setState(() {
            _extraHours = newExtraHours;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTutorial());
    _loadData();
  }

  // --------- TUTORIAL: helpers ---------
  Future<void> _maybeStartTutorial() async {
    if (_started || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_PENDING_FLAG) ?? false;
    if (!(pending || widget.tutorialMode)) return;

    _started = true;
    await _waitForTargetsReady();
    if (!mounted) return;

    final targets = _buildTargets()
        .where((t) => t.keyTarget?.currentContext != null)
        .toList();
    if (targets.isEmpty) {
      await _clearFlags();
      return;
    }

    _coach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.65,
      useSafeArea: true,
      pulseEnable: true,
      textSkip: 'Skip',
      alignSkip: Alignment.bottomRight,
      onClickTarget: (t) async {
        try {
          switch (t.identify) {
            case 'cv_chart':
              break;
            case 'cv_timeframe':
              break;
            case 'cv_back':
              await _clearFlags();

              final p = await SharedPreferences.getInstance();
              await p.setBool('__tutorial_pending__exchange_v1', true);

              try { _coach?.finish(); } catch (_) {}
              if (!mounted) return;
              Navigator.pop(context);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) widget.controller.updateIndex(3);
              });
              break;
          }
        } catch (_) {}
      },
      onClickOverlay: (_) {},
      onSkip: () {
        _clearFlags();
        return true;
      },
      onFinish: () async {
        await _clearFlags();
        // encadenado opcional al siguiente tutorial
        // final p = await SharedPreferences.getInstance();
        // await p.setBool('__tutorial_pending__exact_v1', true);
      },
    );

    _coach!.show(context: context);
  }

  Future<void> _waitForTargetsReady() async {
    for (int i = 0; i < 40; i++) {
      if (!mounted) return;
      final ready =
          _kChart.currentContext != null &&
              _kBack.currentContext  != null &&
              _kZoom.currentContext != null &&
              _kTimeframe.currentContext != null;
    if (ready) break;
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  List<TargetFocus> _buildTargets() {
    Widget bubble(String title, String body) => IgnorePointer(
      ignoring: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 10)],
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              Text(body),
            ],
          ),
        ),
      ),
    );

    return [

      TargetFocus(
        identify: 'cv_zoom',
        keyTarget: _kZoom,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => bubble('Zoom', 'Toca aquí para cambiar el nivel de zoom.'),
          ),
        ],
      ),
      TargetFocus(
        identify: 'cv_exactprice',
        keyTarget: _kExactPrice,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => bubble('Precio exacto', 'Toca aquí para realizar apuestas al cierre de precio exacto.'),
          ),
        ],
      ),
      TargetFocus(
        identify: 'cv_timeframe',
        keyTarget: _kTimeframe,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => bubble('Timemframe', 'Cambia el intervalo de tiempo de cada vela. Los rectángulos de apuesta también cambiarán.'),
          ),
        ],
      ),
      TargetFocus(
        identify: 'cv_chart',
        keyTarget: _kChart,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => bubble('Gráfico', 'Arrastra para moverte. Pellizca horizontalmente para zoom. Desliza el dedo verticalmente sobre la columna de precios para hacer zoom vertical. '
                'Manten pulsado para ver detalles. Pulsa los rectángulos de apuesta para crear una nueva.'),
          ),
        ],
      ),
      TargetFocus(
        identify: 'cv_back',
        keyTarget: _kBack,
        shape: ShapeLightFocus.Circle,
        radius: 40,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (_, __) => bubble('Volver', 'Cierra el gráfico y regresa. También puedes pulsar fuera de él'),
          ),
        ],
      ),
    ];
  }

  Future<void> _clearFlags() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_PENDING_FLAG);
    await p.setBool(_SEEN_FLAG, true);
  }

  // ----------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CandleSticksStyle.dark().background,
      body: SafeArea(
        top: false,
        child: Center(
          child: Stack(
            children: <Widget>[
              ValueListenableBuilder<double>(
                valueListenable: candleScaleNotifier,
                builder: (BuildContext context, double scale, Widget? child) {
                  return Center(
                    child: Stack(
                      children: <Widget>[
                        if (_isLoading)
                          CandlesticksSkeleton()
                        else
                          KeyedSubtree(
                            key: _kChart,
                            child: Candlesticks(
                              candles: _candles,
                              displayZoomActions: true,
                              onScaleUpdate: (double scale) {
                                candleScaleNotifier.value = scale;
                              },
                              rectangleZones: _inactive_zone ? _frozenZonesNotifier : _zonesNotifier,
                              inactiveZone: _inactive_zone,
                              controller: widget.controller,
                              chartTitle: widget.name,
                              ticker: widget.ticker,
                              iconPath: widget.iconPath,
                              extraHours: _extraHours,
                              finishedIcon: _finishedIcon,
                            ),
                          ),

                        if (widget.tutorialMode) ... [
                          Positioned(
                            right: 12,
                            top: 12,
                            child: GestureDetector(
                              key: _kZoom,
                              behavior: HitTestBehavior.opaque,
                              child: const SizedBox(width: 44, height: 20),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 36,
                            child: GestureDetector(
                              key: _kExactPrice,
                              behavior: HitTestBehavior.opaque,
                              child: const SizedBox(width: 44, height: 44),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            top:  MediaQuery.of(context).size.height * 0.52 ,
                            child: GestureDetector(
                              key: _kTimeframe,
                              behavior: HitTestBehavior.opaque,
                              onTap: () => {},
                              child: const SizedBox(width: 25, height: 25),
                            ),
                          ),
                          Positioned(
                            top: 10.0,
                            left: 10.0,
                            child: IconButton(
                              key: _kBack,
                              icon: const Icon(
                                Icons.arrow_back,
                                shadows: [
                                  Shadow(
                                    blurRadius: 3.0,
                                    color: Colors.black45,
                                    offset: Offset(2.5, 2.5),
                                  ),
                                ],
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ]

                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
