//DTO
class BetZone {
  int id;
  String ticker;
  double targetValue;
  double betMargin;
  DateTime startDate;
  DateTime? endDate;
  double targetOdds;
  int betType;

  BetZone({
    required this.id,
    required this.ticker,
    required this.targetValue,
    required this.betMargin,
    required this.startDate,
    this.endDate,
    required this.targetOdds,
    required this.betType
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

  static double _toDouble(dynamic v) => (v == null) ? 0.0 : (v as num).toDouble();
  static int _toInt(dynamic v) => (v == null) ? 0 : (v as num).toInt();

  BetZone.fromJson(Map<String, dynamic> json)
      : id = _toInt(json['id']),
        ticker = (json['ticker']?.toString()) ?? '',
        targetValue = _toDouble(json['targetValue']),
        betMargin = _toDouble(json['betMargin']),
        startDate = _parseDateSafe(json['startDate']),
        endDate = _parseDateSafeOrNull(json['endDate']),
        targetOdds = _toDouble(json['targetOdds']),
        betType = _toInt(json['betType']);

  static DateTime _parseDateSafe(dynamic v) {
    if (v == null || v.toString().trim().isEmpty) return DateTime.now().toUtc();
    try {
      return _parseUtcDate(v.toString());
    } catch (_) {
      return DateTime.now().toUtc();
    }
  }

  static DateTime? _parseDateSafeOrNull(dynamic v) {
    if (v == null || v.toString().trim().isEmpty) return null;
    try {
      return _parseUtcDate(v.toString());
    } catch (_) {
      return null;
    }
  }
}