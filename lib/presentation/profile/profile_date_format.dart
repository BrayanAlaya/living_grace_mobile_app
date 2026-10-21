/// Fechas del perfil en español, sin depender de la zona para un día calendario.
abstract final class ProfileDateFormat {
  static const _months = <String>[
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  /// `1999-09-23` → `23 de Septiembre de 1999`.
  static String? calendarDate(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw.trim());
    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    return '$day de ${_months[month - 1]} de $year';
  }

  /// Date-time ISO convertido al calendario local.
  static String? dateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final local = DateTime.parse(raw.trim()).toLocal();
      final month = local.month.toString().padLeft(2, '0');
      final day = local.day.toString().padLeft(2, '0');
      return calendarDate('${local.year}-$month-$day');
    } on FormatException {
      return null;
    }
  }
}
