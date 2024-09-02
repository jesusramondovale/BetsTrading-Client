//DTO
class BetZone {
  int id;
  String ticker;
  double targetValue;
  double betMargin;
  DateTime startDate;
  DateTime? endDate;
  double targetOdds;

  BetZone({
    required this.id,
    required this.ticker,
    required this.targetValue,
    required this.betMargin,
    required this.startDate,
    this.endDate,
    required this.targetOdds,
  });

  BetZone.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      ticker = json['ticker'],
      targetValue = (json['target_value'] as num).toDouble(),
      betMargin = (json['bet_margin'] as num).toDouble(),
      startDate = DateTime.parse(json['start_date']),
      endDate = json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      targetOdds = (json['target_odds'] as num).toDouble();

}