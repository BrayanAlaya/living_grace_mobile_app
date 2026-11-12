import 'package:flutter/material.dart';

import '../attendance/attendance_qr_api.dart';
import '../core/theme/app_colors.dart';
import '../domain/entities/rehearsal_draft.dart';
import '../presentation/controllers/rehearsal_form_controller.dart';
import '../presentation/widgets/ministry_filter_bar.dart';
import 'rehearsal.dart';
import 'rehearsal_api.dart';
import 'rehearsal_detail_page.dart';
import 'rehearsal_widgets.dart';

const _pageSize = 5;

/// Pantalla "Ensayos": listado paginado y filtrado por ministerio.
class RehearsalsPage extends StatefulWidget {
  const RehearsalsPage({
    super.key,
    required this.api,
    this.formController,
    this.canManage = false,
    this.onChanged,
    this.embedded = false,
  });

  final RehearsalApi api;
  final RehearsalFormController? formController;
  final bool canManage;
  final VoidCallback? onChanged;
  final bool embedded;

  @override
  State<RehearsalsPage> createState() => _RehearsalsPageState();
}

class _RehearsalsPageState extends State<RehearsalsPage> {
  Future<({List<Rehearsal> items, int total})>? _future;
  List<MinistryOption> _ministries = const [];
  int? _ministryId;
  int _page = 1;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final ministries = await widget.api.listMinistries();
      if (!mounted) return;
      setState(() {
        _ministries = ministries;
        _ministryId = ministries.isEmpty ? null : ministries.first.id;
      });
    } catch (_) {
      if (!mounted) return;
    }
    _reload();
  }

  void _reload() {
    final offset = (_page - 1) * _pageSize;
    setState(() {
      _future = widget.api.fetchPage(
        limit: _pageSize,
        offset: offset < 0 ? 0 : offset,
        ministryId: _ministryId,
      );
    });
  }

  void _selectMinistry(int? id) {
    _ministryId = id;
    _page = 1;
    _reload();
  }

  void _goToPage(int page) {
    _page = page;
    _reload();
  }

  Future<void> _openDetail(Rehearsal rehearsal) async {
    var changed = false;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RehearsalDetailPage(
          api: widget.api,
          rehearsalId: rehearsal.id,
          formController: widget.formController,
          canManage: widget.canManage,
          onChanged: () => changed = true,
          attendanceApi: AttendanceQrApi(rehearsalApi: widget.api),
        ),
      ),
    );
    if (!mounted) return;
    if (changed) widget.onChanged?.call();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        if (!widget.embedded)
          const RehearsalHeader(title: 'Ensayos')
        else
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ensayos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        MinistryFilterBar(
          ministries: _ministries,
          selectedId: _ministryId,
          onSelected: _selectMinistry,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: RehearsalSearchField(
            onChanged: (value) => setState(() => _search = value.toLowerCase()),
          ),
        ),
        Expanded(
          child: FutureBuilder<({List<Rehearsal> items, int total})>(
            future: _future,
            builder: (context, snapshot) {
              if (_future == null ||
                  snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No se pudieron cargar los ensayos.'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data!;
              final rehearsals = data.items
                  .where((r) => r.name.toLowerCase().contains(_search))
                  .toList();
              final bounds = pageBounds(
                total: data.total,
                page: _page,
                pageSize: _pageSize,
              );

              return Column(
                children: [
                  Expanded(
                    child: rehearsals.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay ensayos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.label,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            itemCount: rehearsals.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final rehearsal = rehearsals[index];
                              return RehearsalCard(
                                rehearsal: rehearsal,
                                onTap: () => _openDetail(rehearsal),
                              );
                            },
                          ),
                  ),
                  ListPaginationBar(
                    page: bounds.totalPages == 0 ? 1 : _page.clamp(1, bounds.totalPages),
                    totalPages: bounds.totalPages,
                    total: data.total,
                    fromIndex: bounds.fromIndex,
                    toIndex: bounds.toIndex,
                    noun: 'ensayos',
                    onPrevious: _page > 1 ? () => _goToPage(_page - 1) : null,
                    onNext: _page < bounds.totalPages
                        ? () => _goToPage(_page + 1)
                        : null,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(color: AppColors.white, child: body);
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(child: body),
    );
  }
}
