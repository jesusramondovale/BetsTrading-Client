

class RaffleItem {
  final int id;
  final String name;
  final String shortName;
  final int coins;
  final DateTime raffleDate;
  final String icon;
  final int participants;

  RaffleItem(this.id, this.name, this.shortName, this.coins, this.raffleDate, this.icon, this.participants);

  RaffleItem.fromJson(Map<String, dynamic> json)
      : id = (json['id'] as num?)?.toInt() ?? 0,
        name = (json['name']?.toString()) ?? '',
        shortName = (json['shortName']?.toString()) ?? '',
        coins = (json['coins'] as num?)?.toInt() ?? 0,
        raffleDate = _parseRaffleDate(json['raffleDate']),
        icon = (json['icon']?.toString()) ?? '',
        participants = (json['participants'] as num?)?.toInt() ?? 0;

  static DateTime _parseRaffleDate(dynamic v) {
    if (v == null || v.toString().trim().isEmpty) return DateTime.now().toUtc();
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now().toUtc();
    }
  }
}