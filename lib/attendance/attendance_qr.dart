import '../domain/entities/rehearsal_draft.dart';
import '../rehearsals/rehearsal.dart';
import 'attendance_status.dart';

export 'attendance_status.dart';

/// Página de ensayos para generar el QR de asistencia.
class PagedRehearsals {
  const PagedRehearsals({
    required this.items,
    required this.ministries,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<Rehearsal> items;
  final List<MinistryOption> ministries;
  final int page;
  final int pageSize;
  final int total;

  int get totalPages => total == 0 ? 1 : (total / pageSize).ceil();

  bool get hasNext => page < totalPages;

  bool get hasPrevious => page > 1;

  int get fromIndex => total == 0 ? 0 : ((page - 1) * pageSize) + 1;

  int get toIndex {
    final end = page * pageSize;
    return end > total ? total : end;
  }
}

/// Código de asistencia listo para mostrar.
class AttendanceQr {
  const AttendanceQr({
    required this.rehearsal,
    required this.payload,
    required this.generatedAt,
    required this.expiresAt,
  });

  final Rehearsal rehearsal;
  final String payload;
  final DateTime generatedAt;
  final DateTime expiresAt;

  Duration remainingAt(DateTime now) {
    final remaining = expiresAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Resultado de marcar asistencia al escanear el QR.
class AttendanceCheckIn {
  const AttendanceCheckIn({
    required this.rehearsal,
    required this.status,
    required this.markedAt,
  });

  final Rehearsal rehearsal;
  final AttendanceStatus status;
  final DateTime markedAt;
}

class AttendanceCheckInException implements Exception {
  const AttendanceCheckInException(this.message);

  final String message;
}

/// A tiempo si escanea antes de inicio + tolerancia.
String attendanceTimingMessage({
  required DateTime startAt,
  required int toleranceMinutes,
  required DateTime scannedAt,
}) {
  final limit = startAt.add(Duration(minutes: toleranceMinutes));
  return scannedAt.isAfter(limit)
      ? 'Llegaste tarde.'
      : 'Llegaste a tiempo.';
}

/// "07 min 42 seg"
String formatToleranceRemaining(Duration remaining) {
  final totalSeconds = remaining.inSeconds;
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes min $seconds seg';
}
