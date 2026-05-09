import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../helpers/common.dart';
import '../helpers/slider.dart';
import '../locale/localized_texts.dart';
import '../models/users.dart';
import '../services/bets_service.dart';

/// Pantalla de confirmación de copy-trading.
class CopyTradingConfirmPage extends StatefulWidget {
  const CopyTradingConfirmPage({
    super.key,
    required this.user,
    this.tutorialDemoMode = false,
  });

  final User user;
  /// Tour guiado: muestra la pantalla sin ejecutar la confirmación real.
  final bool tutorialDemoMode;

  @override
  State<CopyTradingConfirmPage> createState() => _CopyTradingConfirmPageState();
}

class _CopyTradingConfirmPageState extends State<CopyTradingConfirmPage> {
  static const _storage = FlutterSecureStorage();

  double _myPoints = 0;
  double _manualPercent = 50;
  bool _autoAdjustByBalance = false;
  bool _stopAfterOneLoss = false;
  bool _loadingPoints = true;
  TutorialCoachMark? _confirmTutorialCoach;
  bool _confirmTutorialScheduled = false;
  int _confirmTutorialLayoutRetries = 0;

  final GlobalKey _kTutorialPercentSection = GlobalKey();
  final GlobalKey _kTutorialTogglesSection = GlobalKey();
  final GlobalKey _kTutorialSlideControl = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadMyPoints();
  }

  @override
  void dispose() {
    _disposeConfirmTutorialCoach();
    super.dispose();
  }

  void _disposeConfirmTutorialCoach() {
    try {
      _confirmTutorialCoach?.finish();
    } catch (_) {}
    _confirmTutorialCoach = null;
  }

  Future<void> _loadMyPoints() async {
    final pointsRaw = await _storage.read(key: 'points');
    if (!mounted) return;
    final myPoints = double.tryParse(pointsRaw ?? '0') ?? 0;
    setState(() {
      _myPoints = myPoints;
      _loadingPoints = false;
    });
    _scheduleConfirmTutorialIfNeeded();
  }

  void _scheduleConfirmTutorialIfNeeded() {
    if (!widget.tutorialDemoMode ||
        _confirmTutorialScheduled ||
        _loadingPoints) {
      return;
    }
    _confirmTutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _runConfirmPageTutorial();
      });
    });
  }

  void _runConfirmPageTutorial() {
    if (!mounted || !widget.tutorialDemoMode) return;
    final strings = LocalizedStrings.of(context);

    final targets = [
      TargetFocus(
        identify: 'ct_percent',
        keyTarget: _kTutorialPercentSection,
        shape: ShapeLightFocus.RRect,
        radius: 14,
        enableOverlayTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => Common().bubble(
              strings?.get('tutorial_copy_confirm_phase_percent_title') ??
                  'Copy percentage',
              strings?.get('tutorial_copy_confirm_phase_percent_body') ?? '',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'ct_options',
        keyTarget: _kTutorialTogglesSection,
        shape: ShapeLightFocus.RRect,
        radius: 14,
        enableOverlayTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => Common().bubble(
              strings?.get('tutorial_copy_confirm_phase_options_title') ??
                  'Options',
              strings?.get('tutorial_copy_confirm_phase_options_body') ?? '',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'ct_slide',
        keyTarget: _kTutorialSlideControl,
        shape: ShapeLightFocus.RRect,
        radius: 14,
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => Common().bubble(
              strings?.get('tutorial_copy_confirm_phase_slide_title') ??
                  'Confirm',
              strings?.get('tutorial_copy_confirm_phase_slide_body') ?? '',
            ),
          ),
        ],
      ),
    ].where((t) => t.keyTarget?.currentContext != null).toList();

    if (targets.length < 3) {
      if (_confirmTutorialLayoutRetries < 40) {
        _confirmTutorialLayoutRetries++;
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted &&
              widget.tutorialDemoMode &&
              _confirmTutorialCoach == null) {
            _runConfirmPageTutorial();
          }
        });
      }
      return;
    }
    _confirmTutorialLayoutRetries = 0;

    _confirmTutorialCoach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      textSkip: strings?.get('tutorial_skip') ?? 'Skip tutorial',
      textStyleSkip: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
      hideSkip: true,
      useSafeArea: true,
      pulseEnable: true,
      alignSkip: Alignment.bottomRight,
      initialFocus: 0,
      disableBackButton: true,
      onFinish: () {},
    );
    _confirmTutorialCoach!.show(context: context);
  }

  double get _targetPoints => widget.user.points;

  double get _effectivePercent {
    if (!_autoAdjustByBalance) return _manualPercent;
    if (_targetPoints <= 0) return 0;
    return (_myPoints / _targetPoints) * 100.0;
  }

  String _formatCoins(double value) => NumberFormat.compact().format(value);

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final title = strings?.get('copyTradingConfirmTitle') ?? 'Confirm copy-trading';

    final effectivePercent = _effectivePercent.clamp(0, 9999);
    final percentLabel =
        _autoAdjustByBalance ? 'X%' : '${effectivePercent.toStringAsFixed(0)}%';
    final confirmText = strings?.get('confirmOperation') ?? 'Confirm operation';
    final slideText = strings?.get('confirmBet') ?? 'Slide to confirm the operation';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w300, fontSize: 22),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _disposeConfirmTutorialCoach();
            if (widget.tutorialDemoMode) {
              Navigator.pop(context, false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/android12splash.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent.withValues(alpha: .2)),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              24,
              24,
            ),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KeyedSubtree(
                        key: _kTutorialPercentSection,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              strings?.get('copyBettingPercentageTitle') ?? 'Copy percentage',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              percentLabel,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.greenAccent,
                              ),
                            ),
                            if (!_autoAdjustByBalance) ...[
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor:
                                      Colors.greenAccent.withValues(alpha: 0.85),
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.20),
                                  thumbColor: Colors.greenAccent,
                                  overlayColor:
                                      Colors.greenAccent.withValues(alpha: 0.2),
                                  trackHeight: 6,
                                ),
                                child: Slider(
                                  min: 1,
                                  max: 100,
                                  divisions: 99,
                                  value: _manualPercent.clamp(1, 100),
                                  onChanged: (v) =>
                                      setState(() => _manualPercent = v.roundToDouble()),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 6),
                              Text(
                                strings?.get('copyBettingAutoModeDescription') ??
                                    'Auto mode uses both balances so copied bets keep the same proportional risk.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ],
                        ),
                      ),
                      KeyedSubtree(
                        key: _kTutorialTogglesSection,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),
                            _buildToggleRow(
                              context: context,
                              title: strings?.get('copyBettingAutoAdjustTitle') ??
                                  'Adjust percentage automatically by balances',
                              value: _autoAdjustByBalance,
                              onChanged: (value) =>
                                  setState(() => _autoAdjustByBalance = value),
                            ),
                            _buildToggleRow(
                              context: context,
                              title: strings?.get('copyBettingStopAfterLossTitle') ??
                                  'Stop copying automatically after 1 failed bet',
                              value: _stopAfterOneLoss,
                              onChanged: (value) =>
                                  setState(() => _stopAfterOneLoss = value),
                            ),
                            const SizedBox(height: 8),
                            _buildPreview(
                              context,
                              strings,
                              effectivePercent: effectivePercent.toDouble(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_loadingPoints)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  Text(
                    confirmText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slideText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 8),
                  KeyedSubtree(
                    key: _kTutorialSlideControl,
                    child: SlideToConfirm(
                      betAmount: -1,
                      icon: 'null',
                      circularThumb: true,
                      onSlideComplete: () async {
                        if (widget.tutorialDemoMode) {
                          _disposeConfirmTutorialCoach();
                          if (!mounted) return;
                          Navigator.of(context).pop(true);
                          return;
                        }
                      final requestPercent = _autoAdjustByBalance
                          ? 50.0
                          : _manualPercent.clamp(1, 100).toDouble();
                      final result = await BetsService().configureCopyTrading(
                        targetUserId: widget.user.id,
                        copyPercent: requestPercent,
                        autoAdjustByBalance: _autoAdjustByBalance,
                        stopAfterOneLoss: _stopAfterOneLoss,
                        isEnabled: true,
                      );

                      if (!mounted) return;
                      if (result['success'] == true) {
                        Common().showFloatingSnack(
                          context,
                          strings?.get('copyBettingConfigured') ??
                              'Copy-betting configured successfully',
                        );
                        Navigator.of(context).pop({
                          'percent': effectivePercent.toDouble(),
                          'autoAdjustByBalance': _autoAdjustByBalance,
                          'stopAfterOneLoss': _stopAfterOneLoss,
                        });
                        return;
                      }

                      Common().showFloatingSnack(
                        context,
                        (result['message']?.toString().isNotEmpty ?? false)
                            ? result['message'].toString()
                            : 'Error configurando copy-trading',
                        backgroundColor: Colors.red,
                      );
                    },
                  ),
                ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(
    BuildContext context,
    LocalizedStrings? strings, {
    required double effectivePercent,
  }) {
    final targetExampleBet = (_targetPoints * 0.20);
    final copiedBet = targetExampleBet * (effectivePercent / 100.0);
    final targetName = widget.user.username;
    final targetCoins = _formatCoins(_targetPoints);
    final targetBet = _formatCoins(targetExampleBet);
    final copiedBetText = _formatCoins(copiedBet);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.montserrat(
            fontSize: 12.5,
            height: 1.35,
            color: Colors.white70,
          ),
          children: [
            const TextSpan(text: 'Ejemplo: si '),
            TextSpan(
              text: targetName,
              style: const TextStyle(color: Colors.greenAccent),
            ),
            const TextSpan(text: ' tiene '),
            TextSpan(
              text: targetCoins,
              style: const TextStyle(color: Colors.greenAccent),
            ),
            const TextSpan(text: ' y apuesta '),
            TextSpan(
              text: targetBet,
              style: const TextStyle(color: Colors.greenAccent),
            ),
            const TextSpan(text: ', tú apostarías '),
            TextSpan(
              text: copiedBetText,
              style: const TextStyle(color: Colors.greenAccent),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 13.5,
          color: Colors.white.withValues(alpha: 0.92),
          fontWeight: FontWeight.w500,
          height: 1.25,
        ),
      ),
      trailing: Switch(
        value: value,
        inactiveThumbColor: Colors.black,
        inactiveTrackColor: Colors.grey,
        activeThumbColor: Colors.greenAccent,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }
}
