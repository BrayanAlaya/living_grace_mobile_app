import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../dashboard/dashboard.dart';
import '../rehearsals/rehearsal.dart';
import '../rehearsals/rehearsal_widgets.dart';
import 'attendance_qr.dart';
import 'attendance_widgets.dart';

/// Historial de asistencias del miembro (`recent_attendance`).
class AttendanceHistoryPage extends StatelessWidget {
  const AttendanceHistoryPage({
    super.key,
    this.items = const [],
    this.embedded = false,
    this.fallbackToSamples = true,
  });

  final List<RecentAttendance> items;
  final bool embedded;
  final bool fallbackToSamples;

  static final _samples = <RecentAttendance>[
    RecentAttendance(
      rehearsalId: 1,
      title: 'Ensayo General',
      startAt: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      endAt: DateTime.now().subtract(const Duration(days: 2)),
      status: AttendanceStatus.present,
    ),
    RecentAttendance(
      rehearsalId: 2,
      title: 'Ensayo de voces',
      startAt: DateTime.now().subtract(const Duration(days: 9, hours: 2)),
      endAt: DateTime.now().subtract(const Duration(days: 9)),
      status: AttendanceStatus.late,
    ),
    RecentAttendance(
      rehearsalId: 3,
      title: 'Ensayo de banda',
      startAt: DateTime.now().subtract(const Duration(days: 16, hours: 2)),
      endAt: DateTime.now().subtract(const Duration(days: 16)),
      status: AttendanceStatus.absent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = items.isEmpty && fallbackToSamples ? _samples : items;
    final list = rows.isEmpty
        ? const Center(
            child: Text(
              'Aún no hay asistencias registradas.',
              style: TextStyle(color: AppColors.label),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = rows[index];
              return RoundedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DatePill(text: formatDayMonth(item.displayDate)),
                        AttendanceStatusChip(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatTime(item.startAt)} - ${formatTime(item.endAt)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.label,
                      ),
                    ),
                  ],
                ),
              );
            },
          );

    final body = Column(
      children: [
        if (!embedded)
          const RehearsalHeader(title: 'Asistencias')
        else
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Asistencias',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        Expanded(child: list),
      ],
    );

    if (embedded) {
      return ColoredBox(color: AppColors.white, child: body);
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(child: body),
    );
  }
}
