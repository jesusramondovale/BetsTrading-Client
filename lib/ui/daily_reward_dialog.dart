import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../locale/localized_texts.dart';

/// Shows the 6-day daily login reward journey and allows claiming the current day's coins.
/// Same visual style as [ConsentPage]: background image + AlertDialog.
/// Dialog is not dismissible until user taps the claim button (mandatory).
class DailyRewardDialog extends StatefulWidget {
  final int currentDay;
  final int coinsForCurrentDay;
  final List<int> rewardsByDay;
  final bool canClaim;
  final Future<void> Function() onClaimSuccess;

  const DailyRewardDialog({
    super.key,
    required this.currentDay,
    required this.coinsForCurrentDay,
    required this.rewardsByDay,
    required this.canClaim,
    required this.onClaimSuccess,
  });

  /// Shows the daily reward dialog if [status] indicates showDialog.
  /// Returns after the user closes the dialog (after claiming if canClaim).
  static Future<void> showIfNeeded(
    BuildContext context, {
    required Map<String, dynamic>? status,
    required String userId,
    required Future<void> Function() onClaimSuccess,
  }) async {
    if (kDebugMode) debugPrint('[DAILY_REWARD DIALOG] showIfNeeded status=$status');
    if (status == null || status['showDialog'] != true || status['canClaim'] != true) {
      if (kDebugMode) debugPrint('[DAILY_REWARD DIALOG] showIfNeeded SKIP (status null or showDialog/canClaim false)');
      return;
    }
    final canClaim = status['canClaim'] == true;
    final currentDay = status['currentDay'] as int? ?? 1;
    if (kDebugMode) debugPrint('[DAILY_REWARD DIALOG] showIfNeeded SHOWING dialog currentDay=$currentDay coinsForCurrentDay=${status['coinsForCurrentDay']}');
    final coinsForCurrentDay = status['coinsForCurrentDay'] as int? ?? 5;
    final rewardsByDay = (status['rewardsByDay'] as List<dynamic>?)
            ?.map((e) => e is int ? e : (e as num).toInt())
            .toList() ??
        [5, 10, 15, 25, 40, 50];

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return DailyRewardDialog(
          currentDay: currentDay,
          coinsForCurrentDay: coinsForCurrentDay,
          rewardsByDay: rewardsByDay,
          canClaim: canClaim,
          onClaimSuccess: onClaimSuccess,
        );
      },
    );
  }

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _successScale;
  late Animation<double> _successFade;

  bool _isClaiming = false;
  bool _hasClaimed = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _successFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _handleClaim() async {
    if (_isClaiming || _hasClaimed) return;
    setState(() => _isClaiming = true);
    try {
      if (kDebugMode) debugPrint('[DAILY_REWARD DIALOG] calling onClaimSuccess()');
      final claimFuture = widget.onClaimSuccess();
      // Mínimo ~500 ms mostrando "recogiendo" para que se vea el estado de carga
      final minLoading = Future<void>.delayed(const Duration(milliseconds: 500));
      await Future.wait([claimFuture, minLoading]);
      if (!mounted) return;
      setState(() {
        _isClaiming = false;
        _hasClaimed = true;
      });
      _successController.forward();
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _isClaiming = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : (Colors.grey[900] ?? Colors.black);
    final subtitleColor = isDark ? Colors.white70 : (Colors.grey[700] ?? Colors.grey);

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/backgn.png',
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_entryController, _fadeAnimation]),
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/new_icon.png',
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                strings?.get('dailyReward_title') ?? 'Daily reward',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                strings?.get('dailyReward_subtitle') ?? 'Log in every day to collect your coins',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: subtitleColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              _buildJourneyRow(strings, textColor, subtitleColor),
                              const SizedBox(height: 20),
                              if (widget.canClaim && !_hasClaimed) _buildClaimCta(strings, textColor),
                              if (widget.canClaim && !_hasClaimed) ...[
                                const SizedBox(height: 16),
                                _AnimatedClaimButton(
                                  label: strings?.get('dailyReward_accept') ?? 'Collect',
                                  onPressed: _handleClaim,
                                  isLoading: _isClaiming,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_hasClaimed) _buildSuccessOverlay(textColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessOverlay(Color textColor) {
    final strings = LocalizedStrings.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_successController, _successScale, _successFade]),
      builder: (context, child) {
        return IgnorePointer(
          child: Opacity(
            opacity: _successFade.value,
            child: Transform.scale(
              scale: _successScale.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 64,
                      color: Colors.green.shade400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/coin.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${widget.coinsForCurrentDay}',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClaimCta(LocalizedStrings? strings, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/coin.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            strings?.get('dailyReward_claim')?.replaceAll('{coins}', '${widget.coinsForCurrentDay}') ??
                'Collect ${widget.coinsForCurrentDay} coins',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyRow(LocalizedStrings? strings, Color textColor, Color subtitleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        final day = index + 1;
        final coins = index < widget.rewardsByDay.length
            ? widget.rewardsByDay[index]
            : [5, 10, 15, 25, 40, 50][index];
        final isCurrent = day == widget.currentDay;
        return _DayCell(
          day: day,
          coins: coins,
          isCurrent: isCurrent,
          textColor: textColor,
          subtitleColor: subtitleColor,
          pulseAnimation: _pulseController,
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final int coins;
  final bool isCurrent;
  final Color textColor;
  final Color subtitleColor;
  final Animation<double> pulseAnimation;

  const _DayCell({
    required this.day,
    required this.coins,
    required this.isCurrent,
    required this.textColor,
    required this.subtitleColor,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final scale = isCurrent ? 0.92 + (pulseAnimation.value * 0.16) : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCurrent ? Colors.amber : Colors.grey.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: Colors.orange, width: 2.5)
                  : null,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isCurrent ? Colors.black87 : textColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/coin.png',
                width: 14,
                height: 14,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 2),
              Text(
                NumberFormat.compact().format(coins),
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedClaimButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const _AnimatedClaimButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<_AnimatedClaimButton> createState() => _AnimatedClaimButtonState();
}

class _AnimatedClaimButtonState extends State<_AnimatedClaimButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showPulse = !widget.isLoading;
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: showPulse ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          shadowColor: Colors.amber.withValues(alpha: 0.4),
        ),
        child: widget.isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '...',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                widget.label,
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16),
              ),
      ),
    );
  }
}
