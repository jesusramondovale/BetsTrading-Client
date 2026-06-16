// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../locale/localized_texts.dart';
import '../models/users.dart';
import '../services/bets_service.dart';
import 'copy_trading_confirm_page.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../helpers/common.dart';

/// Pantalla de rendimiento y últimas apuestas de un usuario (Copy-Betting).
class CopyBettingProfilePage extends StatefulWidget {
  const CopyBettingProfilePage({
    super.key,
    required this.user,
    this.tutorialDemoMode = false,
    this.onCopyTutorialDemoComplete,
    this.onCopyTutorialDemoAborted,
  });

  final User user;
  /// Tour guiado Awards: explica copy-trade y la pantalla de confirmación sin aplicar cambios.
  final bool tutorialDemoMode;
  final VoidCallback? onCopyTutorialDemoComplete;
  final VoidCallback? onCopyTutorialDemoAborted;

  @override
  State<CopyBettingProfilePage> createState() => _CopyBettingProfilePageState();
}

class _CopyBettingProfilePageState extends State<CopyBettingProfilePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  bool _loadFailed = false;
  bool _isCopyingTarget = false;
  Map<String, dynamic>? _viewerCopyTrading;
  String? _viewerUserId;
  final GlobalKey _kCopyTutorialIntro = GlobalKey();
  final GlobalKey _kTutorialConfirmBtn = GlobalKey();
  TutorialCoachMark? _profileTutorialCoach;
  bool _profileTutorialScheduled = false;
  int _profileTutorialLayoutRetries = 0;

  bool get _isOwnProfile {
    final viewerId = (_viewerUserId ?? '').trim();
    if (viewerId.isEmpty) return false;
    return viewerId.toLowerCase() == widget.user.id.trim().toLowerCase();
  }

  bool get _showCopyTradingActions =>
      !_isOwnProfile || widget.tutorialDemoMode;

  void _disposeProfileTutorialCoach() {
    try {
      _profileTutorialCoach?.finish();
    } catch (_) {}
    _profileTutorialCoach = null;
  }

  void _scheduleProfileTutorialIfNeeded() {
    if (!widget.tutorialDemoMode ||
        !_showCopyTradingActions ||
        _profileTutorialScheduled ||
        _loading ||
        _loadFailed ||
        !mounted) {
      return;
    }
    _profileTutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runProfileTutorialCoach();
    });
  }

  void _runProfileTutorialCoach() {
    if (!mounted || !widget.tutorialDemoMode || _loadFailed) return;
    final strings = LocalizedStrings.of(context);

    final targets = [
      TargetFocus(
        identify: 'copy_profile_intro',
        keyTarget: _kCopyTutorialIntro,
        shape: ShapeLightFocus.RRect,
        radius: 14,
        enableOverlayTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => Common().bubble(
              strings?.get('tutorial_copy_trade_intro_title') ?? 'Copy-trading',
              strings?.get('tutorial_copy_trade_intro_body') ??
                  'Copy-trading mirrors another player\'s bets with a percentage you choose.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'copy_profile_confirm',
        keyTarget: _kTutorialConfirmBtn,
        shape: ShapeLightFocus.RRect,
        radius: 14,
        enableOverlayTab: false,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => Common().bubble(
              strings?.get('tutorial_copy_profile_title') ?? 'Confirm',
              strings?.get('tutorial_copy_profile_body') ??
                  'Open the confirmation screen to adjust percentage and safeguards.',
            ),
          ),
        ],
      ),
    ].where((t) => t.keyTarget?.currentContext != null).toList();

    if (targets.length < 2) {
      if (_profileTutorialLayoutRetries < 30) {
        _profileTutorialLayoutRetries++;
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted &&
              widget.tutorialDemoMode &&
              _profileTutorialCoach == null) {
            _runProfileTutorialCoach();
          }
        });
      }
      return;
    }
    _profileTutorialLayoutRetries = 0;

    _profileTutorialCoach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      textSkip: strings?.get('tutorial_skip') ?? 'Skip tutorial',
      textStyleSkip: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
      hideSkip: false,
      useSafeArea: true,
      pulseEnable: true,
      alignSkip: Alignment.bottomRight,
      initialFocus: 0,
      disableBackButton: true,
      onClickTarget: (target) async {
        if (target.identify != 'copy_profile_confirm') return;
        _disposeProfileTutorialCoach();
        await Future.delayed(const Duration(milliseconds: 40));
        if (!mounted) return;
        final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => CopyTradingConfirmPage(
              user: widget.user,
              tutorialDemoMode: true,
            ),
          ),
        );
        if (!mounted) return;
        if (ok == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pop();
            widget.onCopyTutorialDemoComplete?.call();
          });
        }
      },
      onSkip: () {
        _disposeProfileTutorialCoach();
        Navigator.of(context).pop();
        widget.onCopyTutorialDemoAborted?.call();
        return true;
      },
      onFinish: () {},
    );
    _profileTutorialCoach!.show(context: context);
  }

  @override
  void initState() {
    super.initState();
    _storage.read(key: 'sessionToken').then((id) {
      if (!mounted) return;
      setState(() => _viewerUserId = id);
    });
    _load();
  }

  @override
  void dispose() {
    _disposeProfileTutorialCoach();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final body = await BetsService().fetchPublicCopyBettingSnapshot(widget.user.id);
    if (!mounted) return;
    if (body == null) {
      setState(() {
        _loading = false;
        _loadFailed = true;
        _stats = null;
        _rows = [];
      });
      return;
    }
    final statsRaw = body['stats'];
    final stats = statsRaw is Map<String, dynamic> ? Map<String, dynamic>.from(statsRaw) : <String, dynamic>{};
    final recent = body['recentBets'] as List? ?? [];
    final rows = <Map<String, dynamic>>[];
    for (final e in recent) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final kind = (m['kind'] ?? '').toString();
      if (kind == 'priceBet') {
        final pb = m['priceBet'];
        if (pb is Map<String, dynamic>) {
          rows.add({...pb, '_type': 'priceBet'});
        } else if (pb is Map) {
          rows.add({...Map<String, dynamic>.from(pb), '_type': 'priceBet'});
        }
      } else if (kind == 'bet') {
        final b = m['bet'];
        if (b is Map<String, dynamic>) {
          rows.add({...b, '_type': 'bet'});
        } else if (b is Map) {
          rows.add({...Map<String, dynamic>.from(b), '_type': 'bet'});
        }
      }
    }
    final viewerRaw = body['viewerCopyTrading'];
    final viewerCopyTrading = viewerRaw is Map<String, dynamic>
        ? Map<String, dynamic>.from(viewerRaw)
        : viewerRaw is Map
            ? Map<String, dynamic>.from(viewerRaw)
            : null;
    final isCopying = viewerCopyTrading?['isActive'] == true;

    setState(() {
      _stats = stats;
      _rows = rows;
      _loading = false;
      _loadFailed = false;
      _isCopyingTarget = isCopying;
      _viewerCopyTrading = viewerCopyTrading;
    });
    _scheduleProfileTutorialIfNeeded();
  }

  static dynamic _get(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v != null) return v;
    }
    return null;
  }

  String _formatDate(dynamic v) {
    if (v == null) return '—';
    DateTime? dt;
    try {
      if (v is String) {
        final clean = v.replaceAll(RegExp(r'([+-]\d{2}:\d{2}|[+-]\d{2})$'), '');
        dt = DateTime.parse(clean).add(const Duration(hours: 2));
      } else if (v is DateTime) {
        dt = v.add(const Duration(hours: 2));
      }
    } catch (_) {
      return v.toString();
    }
    if (dt == null) return v.toString();
    final loc = Localizations.localeOf(context);
    final fmt = DateFormat('d MMM yyyy, HH:mm', loc.toLanguageTag());
    return fmt.format(dt);
  }

  Widget _statusPill(bool success, {double iconSize = 22}) {
    final c = success ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: .5), width: 1),
      ),
      child: Icon(
        success ? FontAwesomeIcons.check : FontAwesomeIcons.xmark,
        size: iconSize,
      ),
    );
  }

  /// Mismo criterio que el contador de monedas: compacto con sufijo K (locale en).
  static String _formatCoinsCompactK(num amount) =>
      NumberFormat.compact(locale: 'en').format(amount);

  Widget _statTile(
    String label,
    String value, {
    Color? valueColor,
    double valueFontSize = 28,
    bool showCoinAfterValue = false,
  }) {
    final textStyle = GoogleFonts.montserrat(
      fontSize: valueFontSize,
      fontWeight: FontWeight.w800,
      height: 1.0,
      color: valueColor ?? Colors.white,
    );
    final coinSize = ((valueFontSize * 0.52).clamp(14.0, 22.0)) * 2;
    final valueChild = showCoinAfterValue
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, maxLines: 1, style: textStyle),
                SizedBox(width: valueFontSize >= 26 ? 8 : 6),
                Image.asset('assets/coin.png', width: coinSize, height: coinSize),
              ],
            ),
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, style: textStyle),
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.15,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          valueChild,
        ],
      ),
    );
  }

  Widget _memoryAvatar(String pic, double size) {
    try {
      return Image.memory(
        base64Decode(pic),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } catch (_) {
      return Image.asset(
        'assets/neon_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
  }

  /// Avatar a la izquierda; nombre y @ a la derecha (compacto, una sola franja vertical).
  Widget _profileHeaderRow({double avatarSize = 64}) {
    final pic = widget.user.profilePic;
    final avatar = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x66000000)),
        child: ClipOval(
          child: pic != null && pic.isNotEmpty
              ? (pic.startsWith('http')
                  ? Image.network(
                      pic,
                      width: avatarSize,
                      height: avatarSize,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/neon_icon.png',
                        width: avatarSize,
                        height: avatarSize,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _memoryAvatar(pic, avatarSize))
              : Image.asset(
                  'assets/neon_icon.png',
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.user.fullname,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.syncopate(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${widget.user.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBetRow(BuildContext context, LocalizedStrings? strings, int index) {
    final row = _rows[index];
    final isPriceBet = row['_type'] == 'priceBet';
    final name = (_get(row, ['name']) ?? '').toString();
    final ticker = (_get(row, ['ticker']) ?? '').toString();
    final icon = (_get(row, ['icon_path', 'iconPath']) ?? '').toString();
    final end = _formatDate(_get(row, ['end_date', 'endDate', 'final_date']));
    bool success = false;
    String amount = '';
    String extra = '';
    if (isPriceBet) {
      success = _get(row, ['paid']) == true;
      amount = (_get(row, ['price_bet', 'priceBet']) ?? '').toString();
      extra = (_get(row, ['margin']) ?? '').toString();
    } else {
      success = _get(row, ['target_won', 'targetWon']) == true;
      amount = (_get(row, ['bet_amount', 'betAmount']) ?? '').toString();
      extra = (_get(row, ['target_odds', 'targetOdds']) ?? '').toString();
    }
    Widget iconChild;
    if (icon.isEmpty) {
      iconChild = const Icon(FontAwesomeIcons.coins, color: Colors.white, size: 18);
    } else if (icon.startsWith('http')) {
      iconChild = ClipOval(
        child: Image.network(icon, fit: BoxFit.cover, width: 28, height: 28),
      );
    } else {
      try {
        iconChild = ClipOval(
          child: Image.memory(
            base64Decode(icon),
            fit: BoxFit.cover,
            width: 28,
            height: 28,
          ),
        );
      } catch (_) {
        iconChild = const Icon(FontAwesomeIcons.coins, color: Colors.white, size: 18);
      }
    }
    return Card(
      color: Colors.white.withAlpha(22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withAlpha(32),
              child: iconChild,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$name ($ticker)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (isPriceBet)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            strings?.get('exactPrice') ?? 'Exact price',
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              color: Colors.amber.shade200,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${strings?.get('betAmount') ?? 'Bet'}: $amount   '
                    '${isPriceBet ? (strings?.get('margin') ?? 'Margin') : (strings?.get('odds') ?? 'Odds')}: $extra',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    end,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _statusPill(success),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final title = strings?.get('copyBettingProfileTitle') ?? 'Copy-Betting';
    final perf = strings?.get('copyBettingPerformanceSection') ?? 'Performance';
    final recentTitle = strings?.get('copyBettingRecentSection') ?? 'Last bets';

    int finished = 0;
    double totalStaked = 0;
    double totalPl = 0;
    int wins = 0;
    int losses = 0;
    double? winRate;
    if (_stats != null) {
      finished = (_stats!['finishedBets'] as num?)?.toInt() ?? 0;
      totalStaked = (_stats!['totalStakedCoins'] as num?)?.toDouble() ?? 0;
      totalPl = (_stats!['totalProfitLossCoins'] as num?)?.toDouble() ?? 0;
      wins = (_stats!['wins'] as num?)?.toInt() ?? 0;
      losses = (_stats!['losses'] as num?)?.toInt() ?? 0;
      final wr = _stats!['winRatePercent'];
      winRate = wr is num ? wr.toDouble() : null;
    }
    final plColor = totalPl > 0
        ? Colors.greenAccent
        : totalPl < 0
            ? Colors.redAccent
            : Colors.white70;
    final stakedStr = _formatCoinsCompactK(totalStaked);
    final pnlStr = totalPl >= 0 ? '+${_formatCoinsCompactK(totalPl)}' : _formatCoinsCompactK(totalPl);

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
            if (widget.tutorialDemoMode) {
              _disposeProfileTutorialCoach();
              Navigator.of(context).pop();
              widget.onCopyTutorialDemoAborted?.call();
            } else {
              Navigator.of(context).pop();
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
              12,
              MediaQuery.of(context).padding.top + kToolbarHeight + 2,
              12,
              6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _profileHeaderRow(),
                const SizedBox(height: 6),
                if (_loading)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.grey)))
                else if (_loadFailed)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 44, color: Colors.white.withValues(alpha: 0.85)),
                          const SizedBox(height: 10),
                          Text(
                            strings?.get('copyBettingLoadError') ?? 'Could not load this profile.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(fontSize: 15, color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _load,
                            child: Text(
                              strings?.get('refresh') ?? 'Refresh',
                              style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: NestedScrollView(
                      physics: const BouncingScrollPhysics(),
                      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                        final overlapHandle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
                        return [
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                KeyedSubtree(
                                  key: _kCopyTutorialIntro,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        perf,
                                        style: GoogleFonts.roboto(
                                          fontSize: 16,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        strings?.get('copyBettingNoStatsHint') ?? '',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 9,
                                          height: 1.0,
                                          color: Colors.white54,
                                        ),
                                        strutStyle: const StrutStyle(
                                          fontSize: 9,
                                          height: 1.0,
                                          leading: 0,
                                          forceStrutHeight: true,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: _statTile(
                                                  strings?.get('copyBettingFinishedBetsCount') ??
                                                      'Finished bets',
                                                  '$finished',
                                                  valueFontSize: 30,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: _statTile(
                                                  strings?.get('copyBettingWinRate') ?? 'Win rate',
                                                  winRate == null ? '—' : '${winRate.toStringAsFixed(1)}%',
                                                  valueFontSize: 30,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: _statTile(
                                                  strings?.get('copyBettingWins') ?? 'Wins',
                                                  '$wins',
                                                  valueColor: Colors.greenAccent.shade100,
                                                  valueFontSize: 30,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: _statTile(
                                                  strings?.get('copyBettingLosses') ?? 'Losses',
                                                  '$losses',
                                                  valueColor: Colors.redAccent.shade100,
                                                  valueFontSize: 30,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: _statTile(
                                                  strings?.get('copyBettingTotalStaked') ??
                                                      'Total staked',
                                                  stakedStr,
                                                  valueFontSize: 24,
                                                  showCoinAfterValue: true,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: _statTile(
                                                  strings?.get('copyBettingTotalProfitLoss') ?? 'PnL',
                                                  pnlStr,
                                                  valueColor: plColor,
                                                  valueFontSize: 24,
                                                  showCoinAfterValue: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_showCopyTradingActions)
                                  Align(
                                    alignment: Alignment.center,
                                    child: KeyedSubtree(
                                      key: _kTutorialConfirmBtn,
                                      child: SizedBox(
                                        height: 44,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.amber.shade700.withValues(alpha: 0.95),
                                                Colors.deepOrange.shade800.withValues(alpha: 0.9),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.28),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(14),
                                              onTap: () async {
                                                final result = await Navigator.of(context).push<dynamic>(
                                                  MaterialPageRoute<dynamic>(
                                                    builder: (_) => CopyTradingConfirmPage(
                                                      user: widget.user,
                                                      tutorialDemoMode: widget.tutorialDemoMode,
                                                      isAlreadyCopying: _isCopyingTarget,
                                                      initialCopyPercent: (_viewerCopyTrading?['copyPercent'] as num?)?.toDouble(),
                                                      initialAutoAdjustByBalance:
                                                          _viewerCopyTrading?['autoAdjustByBalance'] == true,
                                                      initialStopAfterOneLoss:
                                                          _viewerCopyTrading?['stopAfterOneLoss'] == true,
                                                    ),
                                                  ),
                                                );
                                                if (!mounted || result == null) return;
                                                await _load();
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                                child: Center(
                                                  child: Text(
                                                    strings?.get(_isCopyingTarget
                                                            ? 'copyBettingCancelCopyTradingButton'
                                                            : 'copyBettingConfirmCopyTradingButton') ??
                                                        (_isCopyingTarget
                                                            ? 'Cancel copy-trading'
                                                            : 'Confirm copy-trading'),
                                                    style: GoogleFonts.montserrat(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                          SliverOverlapAbsorber(
                            handle: overlapHandle,
                            sliver: SliverPersistentHeader(
                              pinned: true,
                              delegate: _LastBetsSectionHeadingDelegate(title: recentTitle),
                            ),
                          ),
                        ];
                      },
                      body: Builder(
                        builder: (BuildContext context) {
                          final overlapHandle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
                          return CustomScrollView(
                            primary: false,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverOverlapInjector(handle: overlapHandle),
                              if (_rows.isEmpty)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.history, size: 40, color: Colors.white.withValues(alpha: 0.85)),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          child: Text(
                                            strings?.get('copyBettingNoRecentBets') ?? 'No recent bets.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w300,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _buildBetRow(context, strings, index),
                                    childCount: _rows.length,
                                  ),
                                ),
                              const SliverToBoxAdapter(child: SizedBox(height: 20)),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera fija de "Last bets". La altura del delegate debe coincidir con el solapamiento
/// que aplica [SliverOverlapInjector]: solo texto + un poco de aire debajo, sin franjas.
class _LastBetsSectionHeadingDelegate extends SliverPersistentHeaderDelegate {
  _LastBetsSectionHeadingDelegate({required this.title});

  final String title;

  /// ~ línea 16px (height 1.15) + paddings; evita hueco enorme antes de la lista.
  static const double _extent = 36;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: _extent,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 8),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 16,
              height: 1.15,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
            strutStyle: const StrutStyle(
              fontSize: 16,
              height: 1.15,
              leading: 0,
              forceStrutHeight: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => _extent;

  @override
  double get minExtent => _extent;

  @override
  bool shouldRebuild(covariant _LastBetsSectionHeadingDelegate oldDelegate) => oldDelegate.title != title;
}
