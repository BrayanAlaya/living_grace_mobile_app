import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'rehearsal.dart';
import 'rehearsal_api.dart';
import 'rehearsal_detail_page.dart';
import 'rehearsal_widgets.dart';
import 'rehearsals_page.dart';

/// Sección "Ensayos" del dashboard con el próximo ensayo.
class RehearsalHomeCard extends StatefulWidget {
  const RehearsalHomeCard({super.key, required this.api});

  final RehearsalApi api;

  @override
  State<RehearsalHomeCard> createState() => _RehearsalHomeCardState();
}

class _RehearsalHomeCardState extends State<RehearsalHomeCard> {
  late Future<List<Rehearsal>> _future;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchUpcoming();
  }

  void _openList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RehearsalsPage(api: widget.api)),
    );
  }

  void _openDetail(Rehearsal rehearsal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RehearsalDetailPage(api: widget.api, rehearsalId: rehearsal.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            CircleIconButton(icon: Icons.chevron_right_rounded, onPressed: _openList),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Rehearsal>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const RoundedCard(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return const RoundedCard(
                child: Text('No se pudieron cargar los ensayos.'),
              );
            }

            final upcoming = snapshot.data!.take(2).toList();
            if (upcoming.isEmpty) {
              return RoundedCard(
                onTap: _openList,
                child: const Text('No hay ensayos programados.'),
              );
            }

            final selected = upcoming[_selected];
            return RoundedCard(
              onTap: () => _openDetail(selected),
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
                        Expanded(
                          child: _DayChip(
                            rehearsal: upcoming[i],
                            selected: i == _selected,
                            onTap: () => setState(() => _selected = i),
                          ),
                        ),
                        if (i == 0) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  RehearsalTimeRow(rehearsal: selected),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Píldora "11 abril, Sábado" (negra si está seleccionada).
class _DayChip extends StatelessWidget {
  const _DayChip({required this.rehearsal, required this.selected, required this.onTap});

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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.white,
          border: Border.all(color: AppColors.black),
          borderRadius: BorderRadius.circular(20),
        ),
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
    );
  }
}
