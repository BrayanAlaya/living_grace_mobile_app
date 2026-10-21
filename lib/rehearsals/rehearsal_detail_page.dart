import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'rehearsal.dart';
import 'rehearsal_api.dart';
import 'rehearsal_widgets.dart';

/// Detalle de un ensayo (`GET /rehearsals/{id}`).
class RehearsalDetailPage extends StatefulWidget {
  const RehearsalDetailPage({super.key, required this.api, required this.rehearsalId});

  final RehearsalApi api;
  final int rehearsalId;

  @override
  State<RehearsalDetailPage> createState() => _RehearsalDetailPageState();
}

class _RehearsalDetailPageState extends State<RehearsalDetailPage> {
  late Future<Rehearsal> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchDetail(widget.rehearsalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const RehearsalHeader(title: 'Ensayos'),
            Expanded(
              child: FutureBuilder<Rehearsal>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('No se pudo cargar el ensayo.'));
                  }
                  return _DetailContent(rehearsal: snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.rehearsal});

  final Rehearsal rehearsal;

  @override
  Widget build(BuildContext context) {
    final day = rehearsal.isToday ? 'Hoy' : formatWeekday(rehearsal.startAt);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: DatePill(text: '${formatDayMonth(rehearsal.startAt)}, $day'),
        ),
        const SizedBox(height: 16),
        RoundedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rehearsal.name,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Text(
                '${formatTime(rehearsal.startAt)} - ${formatTime(rehearsal.endAt)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _InfoLine(label: 'Ministerio', value: rehearsal.ministryName),
              _InfoLine(label: 'Lidera', value: rehearsal.leaderName),
              _InfoLine(label: 'Propósito', value: rehearsal.description ?? 'Sin descripción'),
              _InfoLine(label: 'Tolerancia', value: '${rehearsal.toleranceMinutes} min'),
              if (rehearsal.participantCount != null)
                _InfoLine(label: 'Participantes', value: '${rehearsal.participantCount}'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Línea "Etiqueta: valor".
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 12, color: AppColors.black),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
