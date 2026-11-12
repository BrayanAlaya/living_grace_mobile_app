import '../domain/entities/rehearsal_draft.dart';
import '../rehearsals/rehearsal.dart';
import '../rehearsals/rehearsal_api.dart';
import 'attendance_qr.dart';

/// Lista ensayos y consume QR / check-in. Sin [rehearsalApi] usa datos locales de prueba.
class AttendanceQrApi {
  AttendanceQrApi({
    this.rehearsalApi,
    this.delay = const Duration(milliseconds: 700),
    List<Rehearsal>? rehearsals,
  }) : _seed = rehearsals ?? simulatedRehearsals;

  final RehearsalApi? rehearsalApi;
  final Duration delay;
  final List<Rehearsal> _seed;

  Future<PagedRehearsals> listRehearsals({
    int? ministryId,
    int page = 1,
    int pageSize = 5,
  }) async {
    if (rehearsalApi != null) {
      final ministries = await rehearsalApi!.listMinistries();
      final offset = (page - 1) * pageSize;
      final result = await rehearsalApi!.fetchPage(
        limit: pageSize,
        offset: offset < 0 ? 0 : offset,
        ministryId: ministryId,
      );
      final total = result.total;
      final totalPages = total == 0 ? 1 : (total / pageSize).ceil();
      final safePage = page.clamp(1, totalPages);
      return PagedRehearsals(
        items: result.items,
        ministries: ministries,
        page: safePage,
        pageSize: pageSize,
        total: total,
      );
    }

    final all = await _all();
    final filtered = [
      for (final rehearsal in all)
        if (ministryId == null || rehearsal.ministryId == ministryId) rehearsal,
    ];
    final total = filtered.length;
    final totalPages = total == 0 ? 1 : (total / pageSize).ceil();
    final safePage = page.clamp(1, totalPages);
    final start = (safePage - 1) * pageSize;
    final end = (start + pageSize).clamp(0, total);

    return PagedRehearsals(
      items: start >= end ? const [] : filtered.sublist(start, end),
      ministries: _ministriesOf(all),
      page: safePage,
      pageSize: pageSize,
      total: total,
    );
  }

  /// `POST /attendance/check-in` con el contenido del QR como `token`.
  Future<AttendanceCheckIn> checkIn({
    required Rehearsal rehearsal,
    required String payload,
  }) async {
    if (rehearsalApi != null) {
      return rehearsalApi!.checkIn(rehearsal: rehearsal, token: payload);
    }
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (payload.trim().isEmpty) {
      throw const AttendanceCheckInException('No se leyó el código QR.');
    }
    if (!payload.contains('rehearsalId=${rehearsal.id}')) {
      throw const AttendanceCheckInException(
        'Este código no corresponde a este ensayo.',
      );
    }
    final markedAt = DateTime.now();
    final lateAfter = rehearsal.startAt.add(
      Duration(minutes: rehearsal.toleranceMinutes),
    );
    final status = markedAt.isAfter(lateAfter)
        ? AttendanceStatus.late
        : AttendanceStatus.present;
    return AttendanceCheckIn(
      rehearsal: rehearsal,
      status: status,
      markedAt: markedAt,
    );
  }

  Future<AttendanceQr> generate(Rehearsal rehearsal) async {
    if (rehearsalApi != null) {
      return rehearsalApi!.createQrSession(rehearsal);
    }
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final generatedAt = DateTime.now();
    final minutes = rehearsal.toleranceMinutes <= 0
        ? 10
        : rehearsal.toleranceMinutes;
    return AttendanceQr(
      rehearsal: rehearsal,
      payload:
          'living-grace://attendance?rehearsalId=${rehearsal.id}&token=sim-${rehearsal.id}-${generatedAt.millisecondsSinceEpoch}',
      generatedAt: generatedAt,
      expiresAt: generatedAt.add(Duration(minutes: minutes)),
    );
  }

  Future<List<Rehearsal>> _all() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return List<Rehearsal>.of(_seed);
  }

  List<MinistryOption> _ministriesOf(List<Rehearsal> rehearsals) {
    final seen = <int>{};
    return [
      for (final rehearsal in rehearsals)
        if (seen.add(rehearsal.ministryId))
          MinistryOption(id: rehearsal.ministryId, name: rehearsal.ministryName),
    ];
  }
}

/// Ensayos de demostración mientras el listado no usa la API real.
final simulatedRehearsals = <Rehearsal>[
  Rehearsal(
    id: 1,
    name: 'Ensayo General',
    description: 'Voces y banda',
    ministryId: 1,
    ministryName: 'Alabanza',
    leaderName: 'Luis Rey',
    startAt: DateTime(2026, 11, 14, 17),
    endAt: DateTime(2026, 11, 14, 19),
    toleranceMinutes: 10,
  ),
  Rehearsal(
    id: 2,
    name: 'Ensayo de voces',
    description: null,
    ministryId: 1,
    ministryName: 'Alabanza',
    leaderName: 'Luis Rey',
    startAt: DateTime(2026, 11, 18, 18),
    endAt: DateTime(2026, 11, 18, 20),
    toleranceMinutes: 8,
  ),
  Rehearsal(
    id: 3,
    name: 'Ensayo de banda',
    description: null,
    ministryId: 1,
    ministryName: 'Alabanza',
    leaderName: 'Luis Rey',
    startAt: DateTime(2026, 11, 21, 17, 30),
    endAt: DateTime(2026, 11, 21, 19, 30),
    toleranceMinutes: 10,
  ),
  Rehearsal(
    id: 4,
    name: 'Coreografía domingo',
    description: null,
    ministryId: 2,
    ministryName: 'Danza',
    leaderName: 'Ana Paz',
    startAt: DateTime(2026, 11, 15, 16),
    endAt: DateTime(2026, 11, 15, 18),
    toleranceMinutes: 5,
  ),
  Rehearsal(
    id: 5,
    name: 'Ensayo de danza',
    description: null,
    ministryId: 2,
    ministryName: 'Danza',
    leaderName: 'Ana Paz',
    startAt: DateTime(2026, 11, 22, 16),
    endAt: DateTime(2026, 11, 22, 18),
    toleranceMinutes: 5,
  ),
  Rehearsal(
    id: 6,
    name: 'Montaje de luces',
    description: null,
    ministryId: 3,
    ministryName: 'Multimedia',
    leaderName: 'Carlos Vega',
    startAt: DateTime(2026, 11, 16, 15),
    endAt: DateTime(2026, 11, 16, 17),
    toleranceMinutes: 15,
  ),
  Rehearsal(
    id: 7,
    name: 'Prueba de sonido',
    description: null,
    ministryId: 3,
    ministryName: 'Multimedia',
    leaderName: 'Carlos Vega',
    startAt: DateTime(2026, 11, 20, 14),
    endAt: DateTime(2026, 11, 20, 16),
    toleranceMinutes: 12,
  ),
  Rehearsal(
    id: 8,
    name: 'Ensayo de alabanza',
    description: null,
    ministryId: 1,
    ministryName: 'Alabanza',
    leaderName: 'Luis Rey',
    startAt: DateTime(2026, 11, 28, 17),
    endAt: DateTime(2026, 11, 28, 19),
    toleranceMinutes: 10,
  ),
  Rehearsal(
    id: 9,
    name: 'Ensayo general danza',
    description: null,
    ministryId: 2,
    ministryName: 'Danza',
    leaderName: 'Ana Paz',
    startAt: DateTime(2026, 11, 29, 16),
    endAt: DateTime(2026, 11, 29, 18),
    toleranceMinutes: 7,
  ),
];
