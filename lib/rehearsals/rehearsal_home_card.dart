import 'package:flutter/material.dart';

import '../attendance/attendance_qr_api.dart';
import '../core/theme/app_colors.dart';
import '../presentation/controllers/rehearsal_form_controller.dart';
import 'rehearsal.dart';
import 'rehearsal_api.dart';
import 'rehearsal_detail_page.dart';
import 'rehearsal_widgets.dart';
import 'rehearsals_page.dart';

/// Sección "Ensayos" del dashboard. Los datos llegan de `GET /dashboard/me`.
class RehearsalHomeCard extends StatefulWidget {
  const RehearsalHomeCard({
    super.key,
    required this.api,
    required this.rehearsals,
    this.formController,
    this.canManage = false,
    this.onSessionChanged,
  });

  final RehearsalApi api;
  final List<Rehearsal> rehearsals;
  final RehearsalFormController? formController;
  final bool canManage;
  final VoidCallback? onSessionChanged;

  @override
  State<RehearsalHomeCard> createState() => _RehearsalHomeCardState();
}

class _RehearsalHomeCardState extends State<RehearsalHomeCard> {
  int _selected = 0;

  @override
  void didUpdateWidget(RehearsalHomeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rehearsals != widget.rehearsals) {
      _selected = 0;
    }
  }

  Future<void> _openList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RehearsalsPage(
          api: widget.api,
          formController: widget.formController,
          canManage: widget.canManage,
        ),
      ),
    );
    if (mounted) widget.onSessionChanged?.call();
  }

  Future<void> _openDetail(Rehearsal rehearsal) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RehearsalDetailPage(
          api: widget.api,
          rehearsalId: rehearsal.id,
          formController: widget.formController,
          canManage: widget.canManage,
          attendanceApi: AttendanceQrApi(rehearsalApi: widget.api),
        ),
      ),
    );
    if (mounted) widget.onSessionChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = widget.rehearsals.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ensayos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            CircleIconButton(
              icon: Icons.chevron_right_rounded,
              onPressed: _openList,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          RoundedCard(
            onTap: _openList,
            child: const Text('No hay ensayos programados.'),
          )
        else
          RoundedCard(
            onTap: () =>
                _openDetail(upcoming[_selected.clamp(0, upcoming.length - 1)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Próximo ensayo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < upcoming.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _DayChip(
                          rehearsal: upcoming[i],
                          selected: i == _selected,
                          onTap: () => setState(() => _selected = i),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                RehearsalTimeRow(
                  rehearsal: upcoming[_selected.clamp(0, upcoming.length - 1)],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Píldora "11 abril, Sábado" (negra si está seleccionada).
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.rehearsal,
    required this.selected,
    required this.onTap,
  });

  final Rehearsal rehearsal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? AppColors.white : AppColors.black;
    final day = rehearsal.isToday ? 'Hoy' : formatWeekday(rehearsal.startAt);
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
                  text: formatDayMonth(rehearsal.startAt),
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
