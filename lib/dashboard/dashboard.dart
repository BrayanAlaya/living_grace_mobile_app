import '../attendance/attendance_qr.dart';
import '../rehearsals/rehearsal.dart';

/// `GET /dashboard/me`
class DashboardSnapshot {
  const DashboardSnapshot({
    this.selectedMinistryId,
    this.profile,
    this.recentAttendance = const [],
    this.nextRehearsal,
    this.upcomingRehearsals = const [],
    this.monthly,
  });

  final int? selectedMinistryId;
  final DashboardProfile? profile;
  final List<RecentAttendance> recentAttendance;
  final Rehearsal? nextRehearsal;
  final List<Rehearsal> upcomingRehearsals;
  final MonthlyAttendance? monthly;

  /// Próximo ensayo y siguientes, sin repetir.
  List<Rehearsal> get rehearsalPreview {
    final items = <int, Rehearsal>{};
    final next = nextRehearsal;
    if (next != null) items[next.id] = next;
    for (final rehearsal in upcomingRehearsals) {
      items.putIfAbsent(rehearsal.id, () => rehearsal);
    }
    return items.values.toList();
  }

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) {
    final recent = json['recent_attendance'] as List? ?? const [];
    final upcoming = json['upcoming_rehearsals'] as List? ?? const [];
    final next = json['next_rehearsal'];
    final monthly = json['ministry_attendance'] ?? json['monthly_attendance'];
    final profile = json['profile'];
    return DashboardSnapshot(
      selectedMinistryId: _asIntOrNull(json['selected_ministry_id']),
      profile: profile is Map
          ? DashboardProfile.fromJson(Map<String, dynamic>.from(profile))
          : null,
      recentAttendance: [
        for (final item in recent)
          if (item is Map)
            RecentAttendance.fromJson(Map<String, dynamic>.from(item)),
      ],
      nextRehearsal: next is Map
          ? Rehearsal.fromJson(Map<String, dynamic>.from(next))
          : null,
      upcomingRehearsals: [
        for (final item in upcoming)
          if (item is Map) Rehearsal.fromJson(Map<String, dynamic>.from(item)),
      ],
      monthly: monthly is Map
          ? MonthlyAttendance.fromJson(Map<String, dynamic>.from(monthly))
          : null,
    );
  }
}

class DashboardProfile {
  const DashboardProfile({
    required this.userId,
    required this.displayName,
    required this.isGlobalAdmin,
    this.accountStatus = '',
    this.memberships = const [],
  });

  final int userId;
  final String displayName;
  final bool isGlobalAdmin;
  final String accountStatus;
  final List<DashboardMembership> memberships;

  factory DashboardProfile.fromJson(Map<String, dynamic> json) {
    final raw = json['memberships'] as List? ?? const [];
    return DashboardProfile(
      userId: _asInt(json['user_id']),
      displayName: (json['display_name'] as String?)?.trim() ?? '',
      accountStatus: (json['account_status'] as String?)?.trim() ?? '',
      isGlobalAdmin: json['is_global_admin'] == true,
      memberships: [
        for (final item in raw)
          if (item is Map)
            DashboardMembership.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}

class DashboardMembership {
  const DashboardMembership({
    required this.ministryMemberId,
    required this.ministryId,
    required this.ministryName,
    this.functions = const [],
  });

  final int ministryMemberId;
  final int ministryId;
  final String ministryName;
  final List<String> functions;

  factory DashboardMembership.fromJson(Map<String, dynamic> json) {
    return DashboardMembership(
      ministryMemberId: _asInt(json['ministry_member_id']),
      ministryId: _asInt(json['ministry_id']),
      ministryName: (json['ministry_name'] as String?)?.trim() ?? '',
      functions: [
        for (final item in json['functions'] as List? ?? const [])
          if (item is String && item.trim().isNotEmpty) item.trim(),
      ],
    );
  }
}

class RecentAttendance {
  const RecentAttendance({
    required this.rehearsalId,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.ministryId,
    this.rehearsalDate,
    this.arrivalAt,
  });

  final int rehearsalId;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final AttendanceStatus status;
  final int? ministryId;

  /// Día del ensayo en el calendario del ministerio (`rehearsal_date`).
  final DateTime? rehearsalDate;
  final DateTime? arrivalAt;

  /// Fecha que se muestra: el día del ensayo, o el inicio si no llegó.
  DateTime get displayDate => rehearsalDate ?? startAt;

  factory RecentAttendance.fromJson(Map<String, dynamic> json) {
    final status = AttendanceStatusLabel.fromApi(json['attendance_status']);
    if (status == null) {
      throw const FormatException('RecentAttendance.status');
    }
    final ministry = json['ministry'];
    final ministryName = ministry is Map ? ministry['name'] as String? : null;
    final ministryId = ministry is Map ? _asIntOrNull(ministry['id']) : null;
    return RecentAttendance(
      rehearsalId: _asInt(json['rehearsal_id']),
      ministryId: ministryId,
      title: (ministryName == null || ministryName.isEmpty)
          ? 'Ensayo'
          : ministryName,
      rehearsalDate: _dateOnly(json['rehearsal_date']),
      startAt: DateTime.parse(json['start_at'] as String).toLocal(),
      endAt: DateTime.parse(json['end_at'] as String).toLocal(),
      status: status,
      arrivalAt: json['arrival_at'] is String
          ? DateTime.tryParse(json['arrival_at'] as String)?.toLocal()
          : null,
    );
  }
}

class MonthlyAttendance {
  const MonthlyAttendance({
    required this.month,
    required this.onTime,
    required this.late,
    required this.absent,
    this.timezone = '',
    this.totalCompleted = 0,
    this.totalRehearsals,
    this.completedRehearsals,
    this.totalMembers,
    this.totalRecords,
    this.attendanceRate,
    this.punctualityRate,
  });

  final String month;
  final String timezone;
  final int onTime;
  final int late;
  final int absent;
  final int totalCompleted;

  /// Solo llega en `ministry_attendance` (administrador).
  final int? totalRehearsals;
  final int? completedRehearsals;
  final int? totalMembers;
  final int? totalRecords;
  final double? attendanceRate;
  final double? punctualityRate;

  bool get isMinistry => totalRehearsals != null;

  factory MonthlyAttendance.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendance(
      month: json['month'] as String? ?? '',
      timezone: (json['timezone'] as String?)?.trim() ?? '',
      onTime: _asInt(json['on_time'] ?? 0),
      late: _asInt(json['late'] ?? 0),
      absent: _asInt(json['absent'] ?? 0),
      totalCompleted: _asInt(
        json['total_completed_assigned_rehearsals'] ??
            json['completed_rehearsals'] ??
            0,
      ),
      totalRehearsals: _asIntOrNull(json['total_rehearsals']),
      completedRehearsals: _asIntOrNull(json['completed_rehearsals']),
      totalMembers: _asIntOrNull(json['total_members']),
      totalRecords: _asIntOrNull(json['total_attendance_records']),
      attendanceRate: _asRate(json['attendance_rate']),
      punctualityRate: _asRate(json['punctuality_rate']),
    );
  }
}

/// El backend a veces manda 0–1 y a veces 0–100.
double? _asRate(Object? raw) {
  if (raw == null) return null;
  if (raw is! num) return null;
  final value = raw.toDouble();
  if (value.isNaN) return null;
  if (value > 1) return (value / 100).clamp(0, 1);
  if (value < 0) return 0;
  return value;
}

int _asInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  throw FormatException('Entero inválido: $raw');
}

int? _asIntOrNull(Object? raw) {
  if (raw == null) return null;
  return _asInt(raw);
}

/// `2026-11-12` se queda en ese día, sin corrimiento por la zona horaria.
DateTime? _dateOnly(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
  if (match == null) return null;
  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}
