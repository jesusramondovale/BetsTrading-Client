import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';

class WithdrawalHistoryPage extends StatefulWidget {
  const WithdrawalHistoryPage({super.key});

  @override
  State<WithdrawalHistoryPage> createState() => _WithdrawalHistoryPageState();
}

class _WithdrawalHistoryPageState extends State<WithdrawalHistoryPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  Timer? _reloadTimer;

  Future<void> _loadWithdrawals() async {
    final userId = await _storage.read(key: 'sessionToken');
    if (userId == null) {
      setState(() {
        _rows = [];
        _loading = false;
      });
      return;
    }

    try {
      final resp = await Common()
          .postRequestWrapper('Info', 'WithdrawalHistory', {'id': userId});

      if ((resp['statusCode'] ?? 500) == 200 && resp['body'] is List) {
        final list = <Map<String, dynamic>>[];
        for (final it in resp['body'] as List) {
          list.add(Map<String, dynamic>.from(it));
        }

        if (!mounted) return;
        setState(() {
          _rows = list;
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

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
    _reloadTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadWithdrawals());
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    super.dispose();
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

  Widget _statusPill(String s) {
    final c = (s.toLowerCase() == 'true') ? Colors.greenAccent : Colors.redAccent;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withValues(alpha: .5), width: 1),
        ),
        child: Icon(
          s == 'true' ? FontAwesomeIcons.check : FontAwesomeIcons.xmark,
          size: 30,
        ));
  }

  Future<void> _showWithdrawalDetails(BuildContext context, Map<String, dynamic> row) async {
    final strings = LocalizedStrings.of(context);
    final Color textColor = Colors.white;

    final id        = (row['id'] ?? '').toString();
    final coins     = (row['coins'] ?? '').toString();
    final amount    = (row['amount'] ?? '').toString();
    final currency  = (row['currency'] ?? '').toString();
    final status    = (row['is_paid'] ?? '').toString();
    final executed  = _formatDate(row['executed_at']);
    String method    = (row['payment_method'] ?? '').toString();

    //TODO...
    if (method.toUpperCase().contains('PAYPAL')){
      method = "PAYPAL";
    }
    else if (method.toUpperCase().contains('AMAZON')){
      method = "AMAZON PAY";
    }
    else if (method.toUpperCase().contains('BANK')){
      method = strings!.get('bankAccount') ?? "bacnk Account";
    }
    else if (method.toUpperCase().contains('XRP')){
      method = "XRP";
    }
    else if (method.toUpperCase().contains('BITCOIN')){
      method = "BITCOIN";
    }
    //TODO...

    final rows = <Widget>[
      _kvRow(strings?.get('coins') ?? 'Coins', coins, textColor),
      const Divider(thickness: 0.2),
      _kvRow(strings?.get('amount') ?? 'Amount', amount + (currency == 'eur' ? ' €' : ' \$'), textColor),
      const Divider(thickness: 0.2),
      _kvRow(strings?.get('completed') ?? 'Completed', status, textColor, statusFlagMode: true),
      const Divider(thickness: 0.2),
      _kvRow(strings?.get('atDate') ?? 'At date', executed, textColor),
      const Divider(thickness: 0.2),
      if (method.isNotEmpty)
        _kvRow(strings?.get('method') ?? 'Method', method.replaceAll('_',' ').toUpperCase(), textColor),
      if (id.isNotEmpty) ...[
        const Divider(thickness: 0.2),
        _kvRow('ID', id, textColor, copyable: true),
      ],
    ];

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent.withValues(alpha: 0.1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white70.withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .6),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Icon(
                              method.toUpperCase().contains('BANK') ?
                              FontAwesomeIcons.buildingColumns :
                              method.toUpperCase().contains('BITCOIN') ?
                              FontAwesomeIcons.bitcoin :
                              method.toUpperCase().contains('XRP') ?
                              FontAwesomeIcons.link :
                              method.toUpperCase().contains('PAYPAL') ?
                              FontAwesomeIcons.paypal :
                              FontAwesomeIcons.buildingColumns,
                              size: 72, color: Colors.white.withValues(alpha: .9)),
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
            size: 25,
          ),
        ],
      );
    } else {
      Widget valueText = Text(
        v.isEmpty ? '—' : v,
        textAlign: TextAlign.right,
        style: GoogleFonts.roboto(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
      );

      if (copyable && v.isNotEmpty) {
        valueText = InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: v));
          },
          child: valueText,
        );
      }

      rightChild = valueText;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              k,
              style: GoogleFonts.montserrat(
                color: textColor.withValues(alpha: .85),
                fontSize: 18,
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
          strings?.get('withdrawalHistory') ?? 'Withdrawal history',
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
              child: Container(color: Colors.transparent.withValues(alpha: 0.2)),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings?.get('recentWithdrawals') ?? 'Your latest withdrawals',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _rows.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                      padding: EdgeInsets.fromLTRB(0, 35, 0, 0),
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final row = _rows[index];
                        final executedAt = _formatDate(row['executed_at']);
                        final amount = (row['amount']?.toString() ?? '').trim();
                        final currency = (row['currency']?.toString() ?? '').trim();
                        final coins    = (row['coins'] ?? '').toString();
                        final status = (row['is_paid']?.toString() ?? '').trim();
                        final method = (row['payment_method']?.toString() ?? '').toLowerCase();

                        Widget leadingIcon;
                        if (method.toUpperCase().contains('PAYPAL')) {
                          leadingIcon = const Icon(FontAwesomeIcons.paypal, color: Colors.white, size: 22);
                        }
                        else if (method.toUpperCase().contains('BITCOIN')) {
                          leadingIcon = const Icon(FontAwesomeIcons.bitcoin, color: Colors.white, size: 22);
                        }
                        else if (method.toUpperCase().contains('BANK')){
                          leadingIcon = const Icon(FontAwesomeIcons.buildingColumns, color: Colors.white, size: 22);
                        }
                        else if (method.toUpperCase().contains('XRP')){
                          leadingIcon = const Icon(FontAwesomeIcons.link, color: Colors.white, size: 22);
                        }
                        else {
                          leadingIcon = const Icon(FontAwesomeIcons.buildingColumns, color: Colors.white, size: 22);
                        }

                        return Card(
                          color: Colors.white.withAlpha(22),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showWithdrawalDetails(context, row),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.white.withAlpha(32),
                                      child: leadingIcon,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                coins.isEmpty ? '—' : coins,
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Image.asset('assets/coin.png', width: 24, height: 24),
                                              const SizedBox(width: 15),
                                              Text(
                                                amount.isEmpty
                                                    ? '—'
                                                    : '($amount${currency == 'eur' ? ' €)' : ' \$)'}',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            executedAt,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.roboto(
                                              fontSize: 13,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _statusPill(status),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 70, color: Colors.white.withValues(alpha: .85)),
          const SizedBox(height: 12),
          Text(
            strings?.get('noWithdrawalsYet') ?? 'No withdrawals yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings?.get('withdrawalsAppearHere') ?? 'Your withdrawals will appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
