import 'package:betrader/candlesticks/candlesticks.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/models/bet_zone.dart';
import 'package:betrader/services/bets_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../helpers/common.dart';
import '../models/bets.dart';
import '../models/rectangle_zone.dart';
import '../services/bet_zone_refresher.dart';
import 'layout_page.dart';

/// A view displaying candlestick charts for financial assets with bet zones.
///
/// Shows price history, allows placing bets on price ranges, and supports
/// multiple timeframes. Includes tutorial mode for onboarding.
class CandlesticksView extends StatefulWidget {
  /// The ticker symbol of the asset.
  final String ticker;
  
  /// The name of the asset.
  final String name;
  
  /// The path to the asset icon (can be asset path, URL, or base64).
  final String iconPath;
  
  /// Controller for managing the main menu navigation.
  final MainMenuPageController controller;
  
  /// Optional bet ID if viewing an existing bet.
  final int? betId;
  
  /// Whether tutorial mode is enabled (disables some interactions).
  final bool tutorialMode;

  const CandlesticksView({
    super.key,
    required this.controller,
    required this.iconPath,
    required this.ticker,
    this.betId,
    required this.name,
    this.tutorialMode = false,
  });

  @override
  CandlesticksViewState createState() => CandlesticksViewState();
}

class CandlesticksViewState extends State<CandlesticksView> with WidgetsBindingObserver {
  final ValueNotifier<double> candleScaleNotifier = ValueNotifier<double>(1.0);
  final ValueNotifier<List<RectangleZone>> _zonesNotifier = ValueNotifier([]);
  late ValueNotifier<List<RectangleZone>> _frozenZonesNotifier = ValueNotifier([]);

  late final List<RectangleZone> _initialZones;
  List<Candle> _candles = [];
  bool _isLoading = true;
  late bool _inactiveZone;
  late int _extraHours;
  int _finishedIcon = 0;
  bool _dollarCurrency = false;

  static const String _pendingFlag = '__tutorial_pending__candles_v1';
  static const String _seenFlag = '__tutorial_seen__candles_v1';
  final _kChart = GlobalKey();
  final _kBack = GlobalKey();
  final _kZoom = GlobalKey();
  final _kExactPrice = GlobalKey();
  final _kTimeframe = GlobalKey();
  TutorialCoachMark? _coach;

  OverlayEntry? _hintEntry;
  final GlobalKey _kBubble = GlobalKey();
  double _bubbleHeight = 0;

  Future<void> _loadData() async {
    try {
      final List<Candle> candles;

      final List<BetZone> betZones = await BetsService().fetchBetZones(
        widget.ticker,
        TimeframeManager.current.value,
        widget.betId,
        currency: (_dollarCurrency ? 'USD' : 'EUR'),
      );

      int finishedIcon = 0;
      if (_inactiveZone) {
        final Bet? theBet = await BetsService().fetchBet(widget.betId.toString(), (_dollarCurrency ? 'USD' : 'EUR'));
        if (theBet != null) {
          if (theBet.finished == true && theBet.targetWon == true) {
            finishedIcon = 1;
          } else if (theBet.finished == true && theBet.targetWon == false) {
            finishedIcon = -1;
          }
        }
      }

      candles = await BetsService().fetchCandles(
        widget.ticker,
        TimeframeManager.current.value,
        (_dollarCurrency ? 'USD' : 'EUR'),
      );

      List<RectangleZone> rectangleZones = Common().getRectangleZonesFromBetZones(
        betZones,
        candles.isNotEmpty ? candles.first.close : 0.0,
      );
      _initialZones = rectangleZones;
      _frozenZonesNotifier = ValueNotifier(_initialZones);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!_inactiveZone) {
          _zonesNotifier.value = _initialZones;
          _finishedIcon = 0;
        } else {
          _finishedIcon = finishedIcon;
        }
        _candles = candles;
      });

      _maybeStartTutorial();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _maybeStartTutorial();
    }
  }

  Future<void> _initCurrencyAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCurrency = prefs.getBool('dollarCurrency') ?? false;
    if (!mounted) return;
    setState(() {
      _dollarCurrency = storedCurrency;
    });
    await _loadData();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TimeframeManager.set(1);
    _inactiveZone = widget.betId != null;
    _extraHours = Common().hoursUntilLatestEndDate(
      _inactiveZone ? _frozenZonesNotifier.value : _zonesNotifier.value,
      _candles.isNotEmpty ? _candles.first.date : DateTime.now().toUtc(),
      TimeframeManager.current.value,
    ) + 1;
    _zonesNotifier.addListener(() {
      if (!_inactiveZone) {
        int newExtraHours = Common().hoursUntilLatestEndDate(
          _zonesNotifier.value,
          _candles.isNotEmpty ? _candles.first.date : DateTime.now().toUtc(),
          TimeframeManager.current.value,
        );
        if (_extraHours != newExtraHours) {
          if (!mounted) return;
          setState(() {
            _extraHours = newExtraHours;
          });
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTutorial());
    _initCurrencyAndLoad();
  }

  Rect _globalRectOf(GlobalKey key) {
    final rb = key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return Rect.zero;
    final topLeft = rb.localToGlobal(Offset.zero);
    return topLeft & rb.size;
  }

  void _continueFromChartHint() {
    _removeChartHintOverlay();

    final targets = _buildTargets(includeChartStep: false)
        .where((t) => t.keyTarget?.currentContext != null)
        .toList();
    if (targets.isEmpty) return;

    _coach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      useSafeArea: true,
      pulseEnable: true,
      disableBackButton: true,
      textSkip: LocalizedStrings.of(context)?.get('tutorial_skip') ?? 'Skip tutorial',
      textStyleSkip: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
      alignSkip: Alignment.bottomRight,
      onSkip: () {
        _clearFlags();
        Common().markAllTutorialsSeen();
        return true;
      },
      onFinish: () async {
        await Future.delayed(const Duration(milliseconds: 150));
        await _clearFlags();
        final p = await SharedPreferences.getInstance();
        await p.setBool('__tutorial_pending__exchange_v1', true);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pop();
          if (mounted) widget.controller.updateIndex(3);
        });

      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _coach?.show(context: context);
    });
  }

  void _showChartHintOverlay() {
    if (_hintEntry != null) return;

    final overlay = Overlay.of(context, rootOverlay: true);

    final strings = LocalizedStrings.of(context);
    final size = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).viewPadding.top;

    _hintEntry = OverlayEntry(
      builder: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final rb = _kBubble.currentContext?.findRenderObject() as RenderBox?;
          if (rb != null) {
            final h = rb.size.height;
            if (h != _bubbleHeight && mounted) {
              setState(() => _bubbleHeight = h);
              _hintEntry?.markNeedsBuild();
            }
          }
        });

        final topHalfRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.5);
        final chartRect = _globalRectOf(_kChart);
        final hole = topHalfRect.intersect(chartRect);

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * 0.5,
          child: Stack(
            children: [
              if (hole != Rect.zero) ...[
                Positioned(
                  left: 0,
                  top: 0,
                  width: size.width,
                  height: hole.top,
                  child: AbsorbPointer(child: Container(color: Colors.transparent)),
                ),
                Positioned(
                  left: 0,
                  top: hole.top,
                  width: hole.left,
                  height: hole.height,
                  child: AbsorbPointer(child: Container(color: Colors.transparent)),
                ),
                Positioned(
                  left: hole.right,
                  top: hole.top,
                  width: size.width - hole.right,
                  height: hole.height,
                  child: AbsorbPointer(child: Container(color: Colors.transparent)),
                ),
                Positioned(
                  left: 0,
                  top: hole.bottom,
                  width: size.width,
                  height: size.height * 0.5 - hole.bottom,
                  child: AbsorbPointer(child: Container(color: Colors.transparent)),
                ),
              ] else ...[
                Positioned.fill(
                  child: AbsorbPointer(child: Container(color: Colors.transparent)),
                ),
              ],

              Positioned(
                left: 16,
                right: 16,
                top: safeTop + 40,
                child: IgnorePointer(
                  key: _kBubble,
                  ignoring: true,
                  child: Common().bubble(
                    strings?.get('cv_chart_title') ?? 'Chart',
                    strings?.get('cv_chart_body') ?? '',
                  ),
                ),
              ),

              Positioned(
                left: 16,
                right: 16,
                top: safeTop + 40 + _bubbleHeight + 12,
                child: Center(
                  child: ElevatedButton(
                    onPressed: _continueFromChartHint,
                    child: Text(
                      strings?.get('tutorial_continue') ?? 'Continuar',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_hintEntry!);
  }

  void _removeChartHintOverlay() {
    _hintEntry?.remove();
    _hintEntry = null;
  }

  Future<void> _maybeStartTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_pendingFlag) ?? false;
    if (!(pending || widget.tutorialMode)) return;

    await _waitForTargetsReady();

    final targets = _buildTargets(includeChartStep: false)
        .where((t) => t.keyTarget?.currentContext != null)
        .toList();
    if (targets.isEmpty) {
      await _clearFlags();
      return;
    }

    _showChartHintOverlay();
  }

  Future<void> _waitForTargetsReady() async {
    for (int i = 0; i < 40; i++) {
      if (!mounted) return;
      final ready = _kChart.currentContext != null &&
          _kBack.currentContext != null &&
          _kZoom.currentContext != null &&
          _kExactPrice.currentContext != null &&
          _kTimeframe.currentContext != null;
      if (ready) break;
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  List<TargetFocus> _buildTargets({bool includeChartStep = false}) {
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
    LocalizedStrings? strings = LocalizedStrings.of(context);
    return [
      if (includeChartStep)
        TargetFocus(
          identify: 'cv_chart',
          keyTarget: _kChart,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          enableTargetTab: false,
          enableOverlayTab: false,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(top: -50),
              builder: (_, __) => bubble(
                strings!.get('cv_chart_title') ?? 'Chart',
                strings.get('cv_chart_body') ?? '...',
              ),
            ),
          ],
        ),
      TargetFocus(
        identify: 'cv_zoom',
        keyTarget: _kZoom,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => bubble(
              strings!.get('cv_zoom_title') ?? 'Zoom',
              strings.get('cv_zoom_body') ??
                  'Tap here to change the horizontal time zoom level. Useful to see more candles at once or focus on recent action.',
            ),
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
            builder: (_, __) => bubble(
              strings!.get('cv_exactprice_title') ?? 'Exact price',
              strings.get('cv_exactprice_body') ??
                  'Place exact-close bets from here. Pick a target close price; if the candle closes exactly at that value, you can win prizes up to €100,000.',
            ),
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
            builder: (_, __) => bubble(
              strings!.get('cv_timeframe_title') ?? 'Timeframe',
              strings.get('cv_timeframe_body') ??
                  'Change the duration of each candle (e.g., 1H, 2H, 4H). Bet rectangles adapt to the selected timeframe.',
            ),
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
            builder: (_, __) => bubble(
              strings!.get('cv_back_title') ?? 'Back',
              strings.get('cv_back_body') ?? 'Close the candlestick view and return. You can also tap outside the sheet to go back.',
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _clearFlags() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_pendingFlag);
    await p.setBool(_seenFlag, true);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_hintEntry != null) {
      _removeChartHintOverlay();
      WidgetsBinding.instance.addPostFrameCallback((_) => _showChartHintOverlay());
    }
  }

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
                              rectangleZones: _inactiveZone ? _frozenZonesNotifier : _zonesNotifier,
                              inactiveZone: _inactiveZone,
                              isTutorial: widget.tutorialMode,
                              controller: widget.controller,
                              chartTitle: widget.name,
                              ticker: widget.ticker,
                              iconPath: widget.iconPath,
                              extraHours: _extraHours,
                              finishedIcon: _finishedIcon,
                            ),
                          ),
                        if (widget.tutorialMode) ...[
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
                            top: MediaQuery.of(context).size.height * 0.52,
                            child: GestureDetector(
                              key: _kTimeframe,
                              behavior: HitTestBehavior.opaque,
                              onTap: () => {},
                              child: const SizedBox(width: 25, height: 25),
                            ),
                          )
                        ],
                        Positioned(
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
                              if (!widget.tutorialMode) Navigator.of(context).pop();
                            },
                          ),
                        ),
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

  @override
  void dispose() {
    _removeChartHintOverlay();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
