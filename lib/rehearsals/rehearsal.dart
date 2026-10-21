/// Ensayo tal como lo devuelve `GET /rehearsals` y `GET /rehearsals/{id}`.
class Rehearsal {
  const Rehearsal({
    required this.id,
    required this.name,
    required this.description,
    required this.ministryName,
    required this.leaderName,
    required this.startAt,
    required this.endAt,
    required this.toleranceMinutes,
    this.participantCount,
  });

  final int id;
  final String name;
  final String? description;
  final String ministryName;
  final String leaderName;
  final DateTime startAt;
  final DateTime endAt;
  final int toleranceMinutes;

  /// Solo llega cuando el usuario es administrador.
  final int? participantCount;

  factory Rehearsal.fromJson(Map<String, dynamic> json) {
    final creator = json['created_by'] as Map<String, dynamic>;
    final ministry = json['ministry'] as Map<String, dynamic>;
    final participants = json['participants'] as List?;

    return Rehearsal(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      ministryName: ministry['name'] as String,
      leaderName: '${creator['first_name']} ${creator['last_name']}',
      startAt: DateTime.parse(json['start_at'] as String).toLocal(),
      endAt: DateTime.parse(json['end_at'] as String).toLocal(),
      toleranceMinutes: json['tolerance_minutes'] as int,
      participantCount:
          json['participant_count'] as int? ?? participants?.length,
    );
  }

  bool get isToday => isSameDay(startAt, DateTime.now());
}

const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

const _weekdays = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// "11 abril"
String formatDayMonth(DateTime date) => '${date.day} ${_months[date.month - 1]}';

/// "Sábado"
String formatWeekday(DateTime date) => _weekdays[date.weekday - 1];

/// "5:00 pm"
String formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'am' : 'pm';
  return '$hour:$minute $period';
}
