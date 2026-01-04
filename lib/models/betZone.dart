//DTO
class BetZone {
  int id;
  String ticker;
  double targetValue;
  double betMargin;
  DateTime startDate;
  DateTime? endDate;
  double targetOdds;
  int bet_type;

  BetZone({
    required this.id,
    required this.ticker,
    required this.targetValue,
    required this.betMargin,
    required this.startDate,
    this.endDate,
    required this.targetOdds,
    required this.bet_type
  });

  // Método auxiliar para parsear fechas asumiendo UTC si no tienen indicador de zona horaria
  static DateTime _parseUtcDate(String dateString) {
    final trimmed = dateString.trim();
    
    // Si la fecha ya termina en 'Z', ya está en UTC
    if (trimmed.endsWith('Z')) {
      return DateTime.parse(trimmed);
    }
    
    // Si tiene un offset de zona horaria (formato +HH:MM o -HH:MM al final)
    // Buscar patrones como +00:00, +05:30, -08:00, etc.
    final offsetPattern = RegExp(r'[+-]\d{2}:\d{2}$');
    if (offsetPattern.hasMatch(trimmed)) {
      final parsed = DateTime.parse(trimmed);
      return parsed.isUtc ? parsed : parsed.toUtc();
    }
    
    // Si no tiene indicador de zona horaria, asumimos que viene en UTC del servidor
    // Normalizar el formato: reemplazar espacio por T si es necesario para formato ISO 8601
    // Luego agregamos 'Z' al final para forzar interpretación como UTC
    // Esto evita que DateTime.parse() lo interprete como hora local del dispositivo
    String normalized = trimmed.replaceFirst(RegExp(r'\s+'), 'T');
    // Si no tiene T ni espacio, intentar agregar T antes de la hora
    if (!normalized.contains('T') && !normalized.contains(' ')) {
      // Formato como "2024-01-0112:00:00" - agregar T
      normalized = normalized.replaceFirst(RegExp(r'(\d{4}-\d{2}-\d{2})(\d{2}:\d{2})'), r'$1T$2');
    }
    final utcDateString = '${normalized}Z';
    return DateTime.parse(utcDateString);
  }

  BetZone.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      ticker = json['ticker'],
      targetValue = (json['target_value'] as num).toDouble(),
      betMargin = (json['bet_margin'] as num).toDouble(),
      startDate = _parseUtcDate(json['start_date']),
      endDate = json['end_date'] != null ? _parseUtcDate(json['end_date']) : null,
      targetOdds = (json['target_odds'] as num).toDouble(),
        bet_type = (json['bet_type'] as num).toInt();

}