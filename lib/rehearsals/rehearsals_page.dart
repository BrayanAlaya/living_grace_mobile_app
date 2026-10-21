import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'rehearsal.dart';
import 'rehearsal_api.dart';
import 'rehearsal_detail_page.dart';
import 'rehearsal_widgets.dart';

/// Pantalla "Ensayos": ensayo de hoy (si hay) y próximos ensayos.
class RehearsalsPage extends StatefulWidget {
  const RehearsalsPage({super.key, required this.api});

  final RehearsalApi api;

  @override
  State<RehearsalsPage> createState() => _RehearsalsPageState();
}

class _RehearsalsPageState extends State<RehearsalsPage> {
  late Future<List<Rehearsal>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchUpcoming();
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
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const RehearsalHeader(title: 'Ensayos'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: RehearsalSearchField(
                onChanged: (value) => setState(() => _search = value.toLowerCase()),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Rehearsal>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('No se pudieron cargar los ensayos.'));
                  }

                  final rehearsals = snapshot.data!
                      .where((r) => r.name.toLowerCase().contains(_search))
                      .toList();
                  final today = rehearsals.where((r) => r.isToday).toList();
                  final upcoming = rehearsals.where((r) => !r.isToday).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 14),
                          children: [
                            TextSpan(
                              text: formatDayMonth(DateTime.now()),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const TextSpan(text: ', Hoy'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (today.isEmpty)
                        const Text(
                          'Sin horarios de ensayo registrados para hoy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      for (final rehearsal in today) ...[
                        RehearsalCard(rehearsal: rehearsal, onTap: () => _openDetail(rehearsal)),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Próximos ensayos',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      if (upcoming.isEmpty)
                        const Text(
                          'No hay próximos ensayos.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.label),
                        ),
                      for (final rehearsal in upcoming) ...[
                        RehearsalCard(rehearsal: rehearsal, onTap: () => _openDetail(rehearsal)),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
