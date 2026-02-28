import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../locale/localized_texts.dart';

/// Shows the 6-day daily login reward journey and allows claiming the current day's coins.
/// Same visual style as [ConsentPage]: background image + AlertDialog.
/// Dialog is not dismissible until user taps the claim button (mandatory).
class DailyRewardDialog extends StatelessWidget {
  final int currentDay;
  final int coinsForCurrentDay;
  final List<int> rewardsByDay;
  final bool canClaim;
  final Future<void> Function() onClaim;

  const DailyRewardDialog({
    super.key,
    required this.currentDay,
    required this.coinsForCurrentDay,
    required this.rewardsByDay,
    required this.canClaim,
    required this.onClaim,
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
          onClaim: () async {
            if (kDebugMode) debugPrint('[DAILY_REWARD DIALOG] user tapped Collect -> calling onClaimSuccess()');
            await onClaimSuccess();
            if (kDebugMode) debugPrint('[DAILY_REWARD DIALOG] onClaimSuccess() returned -> closing dialog');
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
        );
      },
    );
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
          child: AlertDialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            title: Text(
              strings?.get('dailyReward_title') ?? 'Daily reward',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings?.get('dailyReward_subtitle') ?? 'Log in every day to collect your coins',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildJourneyRow(strings, textColor, subtitleColor),
                  const SizedBox(height: 16),
                  if (canClaim)
                    Text(
                      strings?.get('dailyReward_claim')?.replaceAll('{coins}', '$coinsForCurrentDay') ??
                          'Collect $coinsForCurrentDay coins',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              if (canClaim)
                Center(
                  child: ElevatedButton(
                    onPressed: () async => await onClaim(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      strings?.get('dailyReward_accept') ?? 'Collect',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
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
        final coins = index < rewardsByDay.length ? rewardsByDay[index] : [5, 10, 15, 25, 40, 50][index];
        final isCurrent = day == currentDay;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCurrent ? Colors.amber : Colors.grey.withValues(alpha: 0.4),
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: Colors.orange, width: 2) : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? Colors.black : textColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.compact().format(coins),
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: subtitleColor,
              ),
            ),
          ],
        );
      }),
    );
  }
}
