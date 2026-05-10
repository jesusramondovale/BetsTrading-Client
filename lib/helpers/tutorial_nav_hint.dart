import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/src/paint/light_paint_rect.dart'; // ignore: implementation_imports
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:betrader/helpers/common.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/ui/layout_page.dart';

/// Mismo estilo de foco que [TutorialCoachMark] (sombra + recorte redondeado),
/// sin recuadro extra. Los toques solo se interceptan fuera del hueco para que
/// la pestaña del menú inferior reciba el tap como siempre.
Future<void> showTutorialBottomNavNavigateHint({
  required BuildContext context,
  required MainMenuPageController controller,
  required GlobalKey navTabKey,
  required int expectedTabIndex,
  required String title,
  required String body,
  double bottomNavBarHeight = 70,
  Future<void> Function()? onSkipTutorialFlow,
}) async {
  if (!context.mounted) return;
  if (controller.selectedIndexNotifier.value == expectedTabIndex) return;

  final overlayState =
      Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
  if (overlayState == null) return;

  final completer = Completer<void>();
  var finished = false;

  late final VoidCallback indexListener;
  late final OverlayEntry entry;

  void cleanup() {
    if (finished) return;
    finished = true;
    controller.selectedIndexNotifier.removeListener(indexListener);
    try {
      entry.remove();
    } catch (_) {}
  }

  void complete() {
    if (completer.isCompleted) return;
    cleanup();
    completer.complete();
  }

  indexListener = () {
    if (controller.selectedIndexNotifier.value == expectedTabIndex) {
      complete();
    }
  };
  controller.selectedIndexNotifier.addListener(indexListener);

  entry = OverlayEntry(
    builder: (overlayContext) {
      return _BottomNavNavigateHintOverlay(
        navTabKey: navTabKey,
        bottomNavBarHeight: bottomNavBarHeight,
        title: title,
        body: body,
        skipLabel: LocalizedStrings.of(context)?.get('tutorial_skip') ?? 'Skip',
        onSkip: () async {
          await onSkipTutorialFlow?.call();
          complete();
        },
      );
    },
  );

  overlayState.insert(entry);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!completer.isCompleted) {
      try {
        entry.markNeedsBuild();
      } catch (_) {}
    }
  });

  await completer.future;
}

/// Hueco alineado con [LightPaintRect] (misma fórmula que el paquete).
Rect _holeRectAtProgress(
  TargetPosition target,
  double paddingFocus,
  double progress,
  Size canvasSize,
) {
  final maxSize = math.max(canvasSize.width, canvasSize.height) +
      math.max(target.size.width, target.size.height) +
      target.getBiggerSpaceBorder(canvasSize);
  final x =
      -maxSize / 2 * (1 - progress) + target.offset.dx - paddingFocus / 2;
  final y =
      -maxSize / 2 * (1 - progress) + target.offset.dy - paddingFocus / 2;
  final w =
      maxSize * (1 - progress) + target.size.width + paddingFocus;
  final h =
      maxSize * (1 - progress) + target.size.height + paddingFocus;
  return Rect.fromLTWH(x, y, w, h);
}

List<Widget> _dimTouchBarriers(Size screen, Rect hole) {
  Widget barrier() => ColoredBox(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: const SizedBox.expand(),
        ),
      );

  final w = screen.width;
  final h = screen.height;
  final out = <Widget>[];

  if (hole.top > 0) {
    out.add(Positioned(left: 0, right: 0, top: 0, height: hole.top, child: barrier()));
  }
  if (hole.bottom < h) {
    out.add(Positioned(
      left: 0,
      right: 0,
      top: hole.bottom,
      bottom: 0,
      child: barrier(),
    ));
  }
  if (hole.left > 0) {
    out.add(Positioned(
      left: 0,
      width: hole.left,
      top: hole.top,
      height: hole.height,
      child: barrier(),
    ));
  }
  if (hole.right < w) {
    out.add(Positioned(
      left: hole.right,
      right: 0,
      top: hole.top,
      height: hole.height,
      child: barrier(),
    ));
  }
  return out;
}

class _BottomNavNavigateHintOverlay extends StatefulWidget {
  const _BottomNavNavigateHintOverlay({
    required this.navTabKey,
    required this.bottomNavBarHeight,
    required this.title,
    required this.body,
    required this.skipLabel,
    required this.onSkip,
  });

  final GlobalKey navTabKey;
  final double bottomNavBarHeight;
  final String title;
  final String body;
  final String skipLabel;
  final Future<void> Function() onSkip;

  @override
  State<_BottomNavNavigateHintOverlay> createState() =>
      _BottomNavNavigateHintOverlayState();
}

class _BottomNavNavigateHintOverlayState
    extends State<_BottomNavNavigateHintOverlay>
    with TickerProviderStateMixin {
  static const double _paddingFocus = 10;
  static const double _radius = 10;

  /// Entrada del foco: progress 0→1 (sombra cerrándose hacia el botón), como [TutorialCoachMark].
  late final AnimationController _focusInController;
  late final Animation<double> _focusInCurve;

  /// Tras el foco, mismo pulso que el coach (1.0 ↔ 0.99).
  late final AnimationController _pulseController;
  late final Animation<double> _pulseTween;

  bool _focusInComplete = false;
  bool _focusSequenceStarted = false;

  @override
  void initState() {
    super.initState();
    _focusInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _focusInCurve = CurvedAnimation(
      parent: _focusInController,
      curve: Curves.ease,
    );
    _focusInController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _focusInComplete = true);
        _pulseController.forward(from: 0);
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseTween = Tween<double>(begin: 1.0, end: 0.99).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.ease),
    );
    _pulseController.addStatusListener((status) {
      if (!_focusInComplete) return;
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusInController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _ensureFocusSequenceStarted() {
    if (_focusSequenceStarted) return;
    _focusSequenceStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusInController.forward(from: 0);
    });
  }

  TargetPosition? _targetPosition() {
    try {
      return getTargetCurrent(
        TargetFocus(
          identify: 'tutorial_bottom_nav_tab',
          keyTarget: widget.navTabKey,
          shape: ShapeLightFocus.RRect,
          radius: _radius,
        ),
        rootOverlay: true,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mq = MediaQuery.of(context);
    final barTotal = widget.bottomNavBarHeight + mq.padding.bottom;

    final tp = _targetPosition();
    if (tp == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.75),
                ),
              ),
            ),
            Positioned(
              top: mq.padding.top + 8,
              right: 8,
              child: TextButton(
                onPressed: () => widget.onSkip(),
                child: Text(
                  widget.skipLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final target = tp;
    _ensureFocusSequenceStarted();

    final listenable = Listenable.merge([_focusInController, _pulseController]);

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: listenable,
        builder: (context, _) {
          final progress = !_focusInComplete
              ? _focusInCurve.value
              : _pulseTween.value;
          final hole =
              _holeRectAtProgress(target, _paddingFocus, progress, size);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: LightPaintRect(
                      progress: progress,
                      target: target,
                      colorShadow: Colors.black,
                      opacityShadow: 0.75,
                      offset: _paddingFocus,
                      radius: _radius,
                    ),
                  ),
                ),
              ),
              ..._dimTouchBarriers(size, hole),
              Positioned(
                left: 16,
                right: 16,
                bottom: barTotal + 12,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: Common().bubble(widget.title, widget.body),
                ),
              ),
              Positioned(
                top: mq.padding.top + 8,
                right: 8,
                child: TextButton(
                  onPressed: () => widget.onSkip(),
                  child: Text(
                    widget.skipLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
