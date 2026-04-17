enum BetZoneType {
  standard(0),
  extreme(1),
  limit(2);

  const BetZoneType(this.code);
  final int code;

  static BetZoneType fromCode(int code) {
    return BetZoneType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => BetZoneType.standard,
    );
  }
}
