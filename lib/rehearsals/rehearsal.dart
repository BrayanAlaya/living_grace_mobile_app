import '../attendance/attendance_status.dart';

/// Persona convocada a un ensayo (`participants` de `AdminRehearsalDetail`).
class RehearsalParticipant {
  const RehearsalParticipant({
    required this.ministryMemberId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.functions = const [],
    this.arrivalAt,
    this.attendanceStatus,
  });

  final int ministryMemberId;
  final int userId;
  final String firstName;
  final String lastName;
  final List<String> functions;
  final DateTime? arrivalAt;
  final AttendanceStatus? attendanceStatus;

  String get fullName => '$firstName $lastName'.trim();

  factory RehearsalParticipant.fromJson(Map<String, dynamic> json) {
    return RehearsalParticipant(
      ministryMemberId: json['ministry_member_id'] as int,
      userId: json['user_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      functions: [
        for (final item in (json['functions'] as List?) ?? const [])
          if (item is String && item.trim().isNotEmpty) item.trim(),
      ],
      arrivalAt: _date(json['arrival_at']),
      attendanceStatus: AttendanceStatusLabel.fromApi(json['attendance_status']),
    );
  }
}

/// Ensayo tal como lo devuelve `GET /rehearsals` y `GET /rehearsals/{id}`.
class Rehearsal {
  const Rehearsal({
    required this.id,
    required this.name,
    required this.description,
    required this.ministryId,
    required this.ministryName,
    required this.leaderName,
    required this.startAt,
    required this.endAt,
    required this.toleranceMinutes,
    this.participantCount,
    this.participants = const [],
    this.showsMembers = false,
    this.myAttendanceStatus,
    this.myArrivalAt,
  });

  final int id;
  final String name;
  final String? description;
  final int ministryId;
  final String ministryName;
  final String leaderName;
  final DateTime startAt;
  final DateTime endAt;
  final int toleranceMinutes;

  /// Solo llega cuando el usuario es administrador.
  final int? participantCount;

  /// Miembros del ensayo. El detalle de administrador los incluye.
  final List<RehearsalParticipant> participants;

  /// El detalle de administrador trae `participants`, aunque la lista esté vacía.
  final bool showsMembers;

  /// Asistencia del miembro (`MemberRehearsalItem` / `my_attendance`).
  final AttendanceStatus? myAttendanceStatus;
  final DateTime? myArrivalAt;

  factory Rehearsal.fromJson(Map<String, dynamic> json) {
    final creator = json['created_by'];
    final ministry = json['ministry'] as Map<String, dynamic>;
    final rawParticipants = json['participants'] as List?;
    final participants = [
      for (final item in rawParticipants ?? const [])
        if (item is Map<String, dynamic>)
          RehearsalParticipant.fromJson(item)
        else if (item is Map)
          RehearsalParticipant.fromJson(Map<String, dynamic>.from(item)),
    ];
    final mine = json['my_attendance'];
    final myStatus = mine is Map
        ? AttendanceStatusLabel.fromApi(mine['attendance_status'])
        : AttendanceStatusLabel.fromApi(json['attendance_status']);
    final myArrival = mine is Map
        ? _date(mine['arrival_at'])
        : _date(json['arrival_at']);

    return Rehearsal(
      id: (json['id'] ?? json['rehearsal_id']) as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      ministryId: ministry['id'] as int,
      ministryName: ministry['name'] as String,
      leaderName: creator is Map
          ? '${creator['first_name']} ${creator['last_name']}'.trim()
          : '',
      startAt: DateTime.parse(json['start_at'] as String).toLocal(),
      endAt: DateTime.parse(json['end_at'] as String).toLocal(),
      toleranceMinutes: json['tolerance_minutes'] as int,
      participantCount:
          json['participant_count'] as int? ??
          (rawParticipants == null ? null : participants.length),
      participants: participants,
      showsMembers: json.containsKey('participants'),
      myAttendanceStatus: myStatus,
      myArrivalAt: myArrival,
    );
  }

  bool get isToday => isSameDay(startAt, DateTime.now());
}

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const _weekdays = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime? _date(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

/// "11 abril"
String formatDayMonth(DateTime date) =>
    '${date.day} ${_months[date.month - 1]}';

/// "Sábado"
String formatWeekday(DateTime date) => _weekdays[date.weekday - 1];

/// "5:00 pm"
String formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'am' : 'pm';
  return '$hour:$minute $period';
}
