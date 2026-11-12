import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../dashboard/dashboard.dart';
import '../rehearsals/rehearsal.dart';
import '../rehearsals/rehearsal_widgets.dart';
import 'attendance_history_page.dart';
import 'attendance_qr.dart';
import 'attendance_widgets.dart';

/// Sección "Asistencias" del dashboard (`GET /dashboard/me`).
class AttendanceHomeCard extends StatefulWidget {
  const AttendanceHomeCard({super.key, this.items, this.onSessionChanged});

  final List<RecentAttendance>? items;
  final VoidCallback? onSessionChanged;

  @override
  State<AttendanceHomeCard> createState() => _AttendanceHomeCardState();
}

class _AttendanceHomeCardState extends State<AttendanceHomeCard> {
  int _selected = 0;

  static final _samples = <RecentAttendance>[
    RecentAttendance(
      rehearsalId: 1,
      title: 'Ensayo General',
      startAt: DateTime.now().subtract(const Duration(days: 2)),
      endAt: DateTime.now().subtract(const Duration(days: 2, hours: -2)),
      status: AttendanceStatus.present,
    ),
    RecentAttendance(
      rehearsalId: 2,
      title: 'Ensayo de voces',
      startAt: DateTime.now().subtract(const Duration(days: 9)),
      endAt: DateTime.now().subtract(const Duration(days: 9, hours: -2)),
      status: AttendanceStatus.late,
    ),
    RecentAttendance(
      rehearsalId: 3,
      title: 'Ensayo de banda',
      startAt: DateTime.now().subtract(const Duration(days: 16)),
      endAt: DateTime.now().subtract(const Duration(days: 16, hours: -2)),
      status: AttendanceStatus.absent,
    ),
  ];

  @override
  void didUpdateWidget(AttendanceHomeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _selected = 0;
    }
  }

  Future<void> _openHistory(List<RecentAttendance> items) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttendanceHistoryPage(items: items),
      ),
    );
    if (mounted) widget.onSessionChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return _body(widget.items ?? _samples);
  }

  Widget _body(List<RecentAttendance> items) {
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text(
            'Asistencias',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12),
          Text(
            'Aún no hay asistencias registradas.',
            style: TextStyle(color: AppColors.label),
          ),
        ],
      );
    }

    final selected = items[_selected.clamp(0, items.length - 1)];
    final chips = items.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Asistencias',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            CircleIconButton(
              icon: Icons.chevron_right_rounded,
              onPressed: () => _openHistory(items),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RoundedCard(
          onTap: () => _openHistory(items),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Última asistencia',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _DayChip(
                        date: chips[i].displayDate,
                        selected: i == _selected,
                        onTap: () => setState(() => _selected = i),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  AttendanceStatusChip(status: selected.status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selected.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? AppColors.white : AppColors.black;
    final day = isSameDay(date, DateTime.now()) ? 'Hoy' : formatWeekday(date);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.white,
          border: Border.all(color: AppColors.black),
          borderRadius: BorderRadius.circular(20),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 11, color: textColor),
              children: [
                TextSpan(
                  text: formatDayMonth(date),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: ', $day'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
