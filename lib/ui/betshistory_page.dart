// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';

/// A page displaying the complete history of user bets.
///
/// Shows all past bets with their outcomes, dates, and results.
/// Automatically refreshes every 10 seconds to show updated bet statuses.
class BetsHistoryPage extends StatefulWidget {
  const BetsHistoryPage({super.key});

  @override
  State<BetsHistoryPage> createState() => _BetsHistoryPageState();
}

class _BetsHistoryPageState extends State<BetsHistoryPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    _loadBets();
    _reloadTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadBets());
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBets() async {
    final userId = await _storage.read(key: 'sessionToken');
    if (userId == null) {
      setState(() {
        _rows = [];
        _loading = false;
      });
      return;
    }

    try {
      final resp = await Common().postRequestWrapper('Bet', 'HistoricUserBets', {'userId': userId});
      if ((resp['statusCode'] ?? 500) == 200 && resp['body'] is Map) {
        final body = resp['body'] as Map<String, dynamic>;
        final bets = body['bets'] as List? ?? [];
        final priceBets = body['priceBets'] as List? ?? [];

        final List<Map<String, dynamic>> merged = [];

        for (final bet in bets) {
          final m = Map<String, dynamic>.from(bet);
          m['_type'] = 'bet';
          merged.add(m);
        }
        for (final pb in priceBets) {
          final m = Map<String, dynamic>.from(pb);
          m['_type'] = 'priceBet';
          merged.add(m);
        }

        merged.sort((a, b) => _betMergedSortKey(b).compareTo(_betMergedSortKey(a)));

        if (!mounted) return;
        setState(() {
          _rows = merged;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Devuelve el primer valor no null de [keys] (soporta snake_case y camelCase del API).
  static dynamic _get(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v != null) return v;
    }
    return null;
  }

  static DateTime _coerceUtcDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    if (v is DateTime) return v.toUtc();
    if (v is String && v.trim().isNotEmpty) {
      try {
        final clean = v.replaceAll(RegExp(r'([+-]\d{2}:\d{2}|[+-]\d{2})$'), '');
        return DateTime.parse(clean).toUtc();
      } catch (_) {}
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  /// Fecha para ordenar el histórico mixto (zona + precio exacto): fin de ventana, o fallback.
  static DateTime _betMergedSortKey(Map<String, dynamic> row) {
    final primary = _get(row, ['end_date', 'endDate', 'final_date']);
    final fallback = primary == null
        ? _get(row, ['target_date', 'targetDate', 'bet_date', 'betDate'])
        : null;
    return _coerceUtcDate(primary ?? fallback);
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

  Widget _statusPill(bool success) {
    final c = success ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: .5), width: 1),
      ),
      child: Icon(
        success ? FontAwesomeIcons.check : FontAwesomeIcons.xmark,
        size: 26,
      ),
    );
  }

  Future<void> _showDetails(Map<String, dynamic> row) async {
    final strings = LocalizedStrings.of(context);
    final textColor = Colors.white;
    final isPriceBet = row['_type'] == 'priceBet';

    final id        = (_get(row, ['id']) ?? '').toString();
    final name      = (_get(row, ['name']) ?? '').toString();
    final ticker    = (_get(row, ['ticker']) ?? '').toString();
    final endDate   = _formatDate(_get(row, ['end_date', 'endDate', 'final_date']));
    final icon      = (_get(row, ['icon_path', 'iconPath']) ?? '').toString();

    bool? status;
    String amount = '';
    String oddsOrMargin = '';
    String profit = '';

    if (isPriceBet) {
      status = _get(row, ['paid']) == true;
      amount = (_get(row, ['price_bet', 'priceBet']) ?? '').toString();
      oddsOrMargin = (_get(row, ['margin']) ?? '').toString();
      profit = '';
    } else {
      status = _get(row, ['target_won', 'targetWon']) == true;
      amount = (_get(row, ['bet_amount', 'betAmount']) ?? '').toString();
      oddsOrMargin = (_get(row, ['target_odds', 'targetOdds']) ?? '').toString();
      profit = (_get(row, ['profitLoss']) ?? '').toString();
    }

    final rows = <Widget>[
      _kvRow(strings?.get('asset') ?? 'Asset', '$name ($ticker)', textColor),
      const Divider(thickness: 0.2),
      _kvRow(strings?.get('betAmount') ?? 'Bet amount', amount, textColor),
      const Divider(thickness: 0.2),
      _kvRow(isPriceBet ? (strings?.get('margin') ?? 'Margin') : (strings?.get('odds') ?? 'Odds'),
          oddsOrMargin, textColor),
      if (!isPriceBet) ...[
        const Divider(thickness: 0.2),
        _kvRow(strings?.get('profitLoss') ?? 'Profit/Loss', profit, textColor),
      ],
      const Divider(thickness: 0.2),
      _kvRow(strings?.get('completed') ?? 'Completed', status == true ? 'true' : 'false', textColor, statusFlagMode: true),
      const Divider(thickness: 0.2),
      _kvRow(strings?.get('atDate') ?? 'At date', endDate, textColor),
      if (id.isNotEmpty) ...[
        const Divider(thickness: 0.2),
        _kvRow('ID', id, textColor, copyable: true),
      ],
    ];

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent.withValues(alpha: .1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent.withValues(alpha: .02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white70.withValues(alpha: .12),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: icon.isNotEmpty
                              ? (icon.startsWith("http") ?
                                  Image.network(icon, width: 60, height: 60) :
                                  Image.memory(base64Decode(icon), width: 60, height: 60))
                              : const Icon(FontAwesomeIcons.coins, size: 60, color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        ...rows,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _kvRow(String k, String v, Color textColor, {bool statusFlagMode = false, bool copyable = false}) {
    Widget rightChild;
    if (statusFlagMode) {
      rightChild = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            v == 'true' ? FontAwesomeIcons.check : FontAwesomeIcons.xmark,
            size: 24,
          ),
        ],
      );
    } else {
      Widget valueText = Text(
        v.isEmpty ? '—' : v,
        textAlign: TextAlign.right,
        style: GoogleFonts.roboto(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      );

      if (copyable && v.isNotEmpty) {
        valueText = InkWell(
          onTap: () async => await Clipboard.setData(ClipboardData(text: v)),
          child: valueText,
        );
      }
      rightChild = valueText;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              k,
              style: GoogleFonts.montserrat(
                color: textColor.withValues(alpha: .85),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 6, child: rightChild),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          strings?.get('history') ?? 'History',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w300, fontSize: 30),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
              16,
              MediaQuery.of(context).padding.top + kToolbarHeight ,
              16,
              16,
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  strings?.get('recentBets') ?? 'Recent Bets',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 30,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _rows.isEmpty
                      ? const _EmptyStateBets()
                      : ListView.builder(
                    padding: EdgeInsets.fromLTRB(0, 35, 0, 0),
                    itemCount: _rows.length,
                    itemBuilder: (context, index) {
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

                      return Card(
                        color: Colors.white.withAlpha(22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showDetails(row),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.white.withAlpha(32),
                                  child: icon.isNotEmpty
                                      ? ClipOval(child: (icon.startsWith("http") ?
                                          Image.network(icon, fit: BoxFit.cover, width: 32, height: 32) :
                                          Image.memory(base64Decode(icon), fit: BoxFit.cover, width: 32, height: 32))
                                        )
                                      : const Icon(FontAwesomeIcons.coins, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$name ($ticker)',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${strings?.get('betAmount') ?? 'Bet'}: $amount   '
                                            '${isPriceBet ? (strings?.get('margin') ?? 'Margin') : (strings?.get('odds') ?? 'Odds')}: $extra',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        end,
                                        style: GoogleFonts.roboto(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _statusPill(success),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateBets extends StatelessWidget {
  const _EmptyStateBets();

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 56, color: Colors.white.withValues(alpha: .85)),
          const SizedBox(height: 12),
          Text(
            textAlign: TextAlign.center,
            strings?.get('noBetsYet') ?? 'No bets yet',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings?.get('betsAppearHere') ?? 'Your bets will appear here',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
