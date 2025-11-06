

class RaffleItem {
  final int id;
  final String name;
  final String shortName;
  final int coins;
  final DateTime raffleDate;
  final String icon;
  final int participants;

  RaffleItem(this.id, this.name, this.shortName, this.coins, this.raffleDate, this.icon, this.participants);

  RaffleItem.fromJson(Map<String, dynamic> json) :
      id = json['id'],
      name = json['name'],
      shortName = json['short_name'],
      coins = json['coins'],
      raffleDate = DateTime.parse(json['raffle_date']),
      icon = json['icon'],
      participants = json['participants'];
  }