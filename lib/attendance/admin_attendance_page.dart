import 'package:flutter/material.dart';

import '../core/layouts/app_layout.dart';
import '../core/theme/app_colors.dart';
import '../domain/entities/rehearsal_draft.dart';
import '../presentation/widgets/ministry_filter_bar.dart';
import '../rehearsals/rehearsal.dart';
import '../rehearsals/rehearsal_api.dart';
import 'attendance_qr.dart';
import 'attendance_qr_api.dart';
import 'attendance_widgets.dart';

const _pageSize = 5;

class _RosterMember {
  const _RosterMember({
    required this.name,
    required this.role,
    this.status,
  });

  final String name;
  final String role;
  final AttendanceStatus? status;
}

class _Roster {
  const _Roster({required this.rehearsal, required this.members});

  final Rehearsal rehearsal;
  final List<_RosterMember> members;
}

/// Listado de asistencias para el administrador.
class AdminAttendancePage extends StatefulWidget {
  const AdminAttendancePage({
    super.key,
    required this.onBack,
    this.rehearsalApi,
    this.showHeader = true,
  });

  final VoidCallback onBack;
  final RehearsalApi? rehearsalApi;
  final bool showHeader;

  @override
  State<AdminAttendancePage> createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends State<AdminAttendancePage> {
  Future<({List<Rehearsal> items, int total})>? _future;
  final _details = <int, Rehearsal>{};
  List<MinistryOption> _ministries = const [];
  int? _ministryId;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final api = widget.rehearsalApi;
    if (api != null) {
      try {
        final ministries = await api.listMinistries();
        if (!mounted) return;
        setState(() {
          _ministries = ministries;
          _ministryId = ministries.isEmpty ? null : ministries.first.id;
        });
      } catch (_) {}
    } else {
      final seen = <int>{};
      _ministries = [
        for (final rehearsal in simulatedRehearsals)
          if (seen.add(rehearsal.ministryId))
            MinistryOption(
              id: rehearsal.ministryId,
              name: rehearsal.ministryName,
            ),
      ];
      _ministryId = _ministries.isEmpty ? null : _ministries.first.id;
    }
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<({List<Rehearsal> items, int total})> _load() async {
    if (widget.rehearsalApi == null) {
      final all = [
        for (final rehearsal in simulatedRehearsals)
          if (_ministryId == null || rehearsal.ministryId == _ministryId)
            rehearsal,
      ];
      final total = all.length;
      final start = (_page - 1) * _pageSize;
      final end = (start + _pageSize).clamp(0, total);
      return (
        items: start >= total ? const <Rehearsal>[] : all.sublist(start, end),
        total: total,
      );
    }
    return widget.rehearsalApi!.fetchPage(
      limit: _pageSize,
      offset: (_page - 1) * _pageSize,
      ministryId: _ministryId,
    );
  }

  void _selectMinistry(int? id) {
    _ministryId = id;
    _page = 1;
    _reload();
  }

  Future<void> _ensureDetail(Rehearsal rehearsal) async {
    final api = widget.rehearsalApi;
    if (api == null || _details.containsKey(rehearsal.id)) return;
    final detail = await api.fetchDetail(rehearsal.id);
    if (!mounted) return;
    setState(() => _details[rehearsal.id] = detail);
  }

  List<_RosterMember> _membersOf(Rehearsal rehearsal) {
    if (widget.rehearsalApi == null) {
      return _simulatedMembers(rehearsal.id);
    }
    final detail = _details[rehearsal.id];
    if (detail == null) return const [];
    return [
      for (final participant in detail.participants)
        _RosterMember(
          name: participant.fullName,
          role: participant.functions.join(' · '),
          status: participant.attendanceStatus,
        ),
    ];
  }

  static List<_RosterMember> _simulatedMembers(int rehearsalId) {
    const names = [
      ('Ana Paz', 'Voz'),
      ('Luis Rey', 'Guitarra'),
      ('Carlos Vega', 'Sonido'),
      ('María Sol', 'Danza'),
    ];
    final statuses = AttendanceStatus.values;
    return [
      for (var i = 0; i < names.length; i++)
        _RosterMember(
          name: names[i].$1,
          role: names[i].$2,
          status: statuses[(rehearsalId + i) % statuses.length],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
        children: [
          if (widget.showHeader)
            _AttendanceHeader(onBack: widget.onBack)
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Asistencias',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          MinistryFilterBar(
            ministries: _ministries,
            selectedId: _ministryId,
            onSelected: _selectMinistry,
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
                    child: TextButton(
                      onPressed: _reload,
                      child: const Text('Reintentar'),
                    ),
                  );
                }
                final data = snapshot.data!;
                final rehearsals = data.items;
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
                              child: Text('No hay ensayos para mostrar.'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                              itemCount: rehearsals.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final rehearsal = rehearsals[index];
                                return _RehearsalAttendanceCard(
                                  roster: _Roster(
                                    rehearsal: rehearsal,
                                    members: _membersOf(rehearsal),
                                  ),
                                  loadingMembers:
                                      widget.rehearsalApi != null &&
                                      !_details.containsKey(rehearsal.id),
                                  onExpand: () => _ensureDetail(rehearsal),
                                );
                              },
                            ),
                    ),
                    ListPaginationBar(
                      page: _page.clamp(1, bounds.totalPages),
                      totalPages: bounds.totalPages,
                      total: data.total,
                      fromIndex: bounds.fromIndex,
                      toIndex: bounds.toIndex,
                      noun: 'ensayos',
                      onPrevious: _page > 1
                          ? () {
                              _page -= 1;
                              _reload();
                            }
                          : null,
                      onNext: _page < bounds.totalPages
                          ? () {
                              _page += 1;
                              _reload();
                            }
                          : null,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );

    if (!widget.showHeader) {
      return ColoredBox(color: AppColors.white, child: body);
    }

    return AppLayout(
      backgroundColor: AppColors.white,
      statusBarBrightness: Brightness.light,
      extendBodyBehindSafeArea: true,
      child: body,
    );
  }
}

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              Tooltip(
                message: 'Administración',
                child: Material(
                  color: AppColors.inputFill,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 28,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Asistencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 46),
            ],
          ),
        ),
      ),
    );
  }
}

class _RehearsalAttendanceCard extends StatelessWidget {
  const _RehearsalAttendanceCard({
    required this.roster,
    required this.onExpand,
    this.loadingMembers = false,
  });

  final _Roster roster;
  final VoidCallback onExpand;
  final bool loadingMembers;

  @override
  Widget build(BuildContext context) {
    final rehearsal = roster.rehearsal;
    return Material(
      color: AppColors.white,
      elevation: 4,
      shadowColor: AppColors.black.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          onExpansionChanged: (open) {
            if (open) onExpand();
          },
          title: Text(
            rehearsal.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${rehearsal.ministryName} · ${formatDayMonth(rehearsal.startAt)} · ${formatTime(rehearsal.startAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.label),
            ),
          ),
          children: [
            if (loadingMembers)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (roster.members.isEmpty)
              const Text(
                'Este ensayo no tiene miembros.',
                style: TextStyle(color: AppColors.label),
              )
            else
              for (var i = 0; i < roster.members.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 16,
                    thickness: 1,
                    color: AppColors.inputFill,
                  ),
                _MemberStatusRow(member: roster.members[i]),
              ],
          ],
        ),
      ),
    );
  }
}

class _MemberStatusRow extends StatelessWidget {
  const _MemberStatusRow({required this.member});

  final _RosterMember member;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.inputFill,
          child: Icon(Icons.person_rounded, size: 16, color: AppColors.label),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (member.role.isNotEmpty)
                Text(
                  member.role,
                  style: const TextStyle(fontSize: 12, color: AppColors.label),
                ),
            ],
          ),
        ),
        if (member.status != null)
          AttendanceStatusChip(status: member.status!)
        else
          const Text(
            'Sin marcar',
            style: TextStyle(fontSize: 12, color: AppColors.label),
          ),
      ],
    );
  }
}
