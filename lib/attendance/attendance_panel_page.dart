import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../dashboard/dashboard.dart';
import '../dashboard/dashboard_api.dart';
import '../domain/entities/rehearsal_draft.dart';
import '../presentation/widgets/ministry_filter_bar.dart';
import 'attendance_history_page.dart';

const _pageSize = 5;

/// Asistencias del miembro en el panel (`GET /dashboard/me`).
class AttendancePanelPage extends StatefulWidget {
  const AttendancePanelPage({super.key, this.api});

  final DashboardApi? api;

  @override
  State<AttendancePanelPage> createState() => _AttendancePanelPageState();
}

class _AttendancePanelPageState extends State<AttendancePanelPage> {
  Future<DashboardSnapshot>? _future;
  List<MinistryOption> _ministries = const [];
  int? _ministryId;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<DashboardSnapshot> _load() async {
    final api = widget.api;
    if (api == null) {
      return const DashboardSnapshot();
    }
    final snapshot = await api.fetch(ministryId: _ministryId);
    final first = snapshot.profile?.memberships.isNotEmpty == true
        ? snapshot.profile!.memberships.first.ministryId
        : null;
    if (_ministryId == null && first != null) {
      _ministries = [
        for (final membership in snapshot.profile!.memberships)
          MinistryOption(
            id: membership.ministryId,
            name: membership.ministryName,
          ),
      ];
      _ministryId = first;
      if (snapshot.selectedMinistryId != first) {
        return api.fetch(ministryId: first);
      }
    } else if (snapshot.profile != null) {
      _ministries = [
        for (final membership in snapshot.profile!.memberships)
          MinistryOption(
            id: membership.ministryId,
            name: membership.ministryName,
          ),
      ];
    }
    return snapshot;
  }

  void _selectMinistry(int? id) {
    _ministryId = id;
    _page = 1;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: FutureBuilder<DashboardSnapshot>(
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
                  const Text(
                    'No se pudieron cargar las asistencias.',
                    style: TextStyle(color: AppColors.label),
                  ),
                  TextButton(onPressed: _reload, child: const Text('Reintentar')),
                ],
              ),
            );
          }

          final items = snapshot.data?.recentAttendance ?? const [];
          final bounds = pageBounds(
            total: items.length,
            page: _page,
            pageSize: _pageSize,
          );
          final start = (_page - 1) * _pageSize;
          final pageItems = start >= items.length
              ? const <RecentAttendance>[]
              : items.sublist(
                  start,
                  start + _pageSize > items.length
                      ? items.length
                      : start + _pageSize,
                );

          return Column(
            children: [
              MinistryFilterBar(
                ministries: _ministries,
                selectedId: _ministryId,
                onSelected: _selectMinistry,
              ),
              Expanded(
                child: AttendanceHistoryPage(
                  items: pageItems,
                  embedded: true,
                  fallbackToSamples: false,
                ),
              ),
              ListPaginationBar(
                page: _page.clamp(1, bounds.totalPages),
                totalPages: bounds.totalPages,
                total: items.length,
                fromIndex: bounds.fromIndex,
                toIndex: bounds.toIndex,
                noun: 'asistencias',
                onPrevious: _page > 1
                    ? () => setState(() => _page -= 1)
                    : null,
                onNext: _page < bounds.totalPages
                    ? () => setState(() => _page += 1)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
