import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../attendance/attendance_home_card.dart';
import '../core/navigation/app_route_observer.dart';
import '../core/theme/app_colors.dart';
import '../presentation/controllers/rehearsal_form_controller.dart';
import '../rehearsals/rehearsal_api.dart';
import '../rehearsals/rehearsal_home_card.dart';
import '../rehearsals/rehearsal_widgets.dart';
import 'dashboard.dart';
import 'dashboard_api.dart';

/// Contenido del home alimentado por `GET /dashboard/me`.
class DashboardHome extends StatefulWidget {
  const DashboardHome({
    super.key,
    required this.name,
    required this.rehearsalApi,
    this.dashboardApi,
    this.loadingName = false,
    this.rehearsalFormController,
    this.canManageRehearsals = false,
  });

  final String name;
  final bool loadingName;
  final RehearsalApi rehearsalApi;
  final DashboardApi? dashboardApi;
  final RehearsalFormController? rehearsalFormController;
  final bool canManageRehearsals;

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> with RouteAware {
  DashboardSnapshot? _snapshot;
  Object? _error;
  bool _loading = false;
  int? _ministryId;

  bool get _usesApi => widget.dashboardApi != null;

  @override
  void initState() {
    super.initState();
    if (_usesApi) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.unsubscribe(this);
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(DashboardHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dashboardApi != widget.dashboardApi && _usesApi) {
      _load();
    }
  }

  @override
  void didPopNext() {
    if (_usesApi) _load();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _load() async {
    final api = widget.dashboardApi;
    if (api == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await api.fetch(ministryId: _ministryId);
      if (!mounted) return;
      final firstMinistry = snapshot.profile?.memberships.isNotEmpty == true
          ? snapshot.profile!.memberships.first.ministryId
          : null;
      final nextMinistryId = _ministryId ?? firstMinistry ?? snapshot.selectedMinistryId;
      final shouldReloadFirst =
          _ministryId == null &&
          firstMinistry != null &&
          snapshot.selectedMinistryId != firstMinistry;

      setState(() {
        _snapshot = snapshot;
        _ministryId = nextMinistryId;
        _loading = false;
      });
      if (shouldReloadFirst) {
        await _load();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _selectMinistry(int id) {
    if (_ministryId == id && _snapshot != null) return;
    _ministryId = id;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hola',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.label,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
            SizedBox(
              height: 40,
              child: widget.loadingName && _greeting.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Text(
                      _greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        height: 1.1,
                      ),
                    ),
            ),
        const SizedBox(height: 20),
        if (_memberships.isNotEmpty) ...[
          _MinistrySelector(
            memberships: _memberships,
            selectedId: _ministryId,
            onSelected: _selectMinistry,
          ),
          const SizedBox(height: 20),
        ],
        if (_usesApi && _loading && _snapshot == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_usesApi && _error != null && _snapshot == null)
          RoundedCard(
            onTap: _load,
            child: const Text(
              'No se pudo cargar el dashboard. Toca para reintentar.',
            ),
          )
        else ...[
          if (_snapshot?.monthly != null) ...[
            _MonthlyCard(monthly: _snapshot!.monthly!),
            const SizedBox(height: 28),
          ],
          RehearsalHomeCard(
            api: widget.rehearsalApi,
            rehearsals: _snapshot?.rehearsalPreview ?? const [],
            formController: widget.rehearsalFormController,
            canManage: widget.canManageRehearsals,
          ),
          if (!widget.canManageRehearsals &&
              _snapshot?.profile?.isGlobalAdmin != true) ...[
            const SizedBox(height: 28),
            AttendanceHomeCard(
              items: _snapshot?.recentAttendance ?? const [],
            ),
          ],
        ],
      ],
    );
  }

  List<DashboardMembership> get _memberships =>
      _snapshot?.profile?.memberships ?? const [];

  String get _greeting {
    final fromDashboard = _snapshot?.profile?.displayName.trim() ?? '';
    if (fromDashboard.isNotEmpty) {
      return fromDashboard.split(' ').first;
    }
    return widget.name;
  }
}

class _MinistrySelector extends StatelessWidget {
  const _MinistrySelector({
    required this.memberships,
    required this.selectedId,
    required this.onSelected,
  });

  final List<DashboardMembership> memberships;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ministerio',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.label,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: memberships.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final ministry = memberships[index];
              final selected = ministry.ministryId == selectedId;
              return Material(
                key: ValueKey('dashboard-ministry-${ministry.ministryId}'),
                color: selected ? AppColors.black : AppColors.inputFill,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelected(ministry.ministryId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        ministry.ministryName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.white : AppColors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthlyCard extends StatelessWidget {
  const _MonthlyCard({required this.monthly});

  final MonthlyAttendance monthly;

  @override
  Widget build(BuildContext context) {
    final slices = [
      _Slice('Presente', monthly.onTime, AppColors.success),
      _Slice('Tarde', monthly.late, AppColors.warning),
      _Slice('Ausente', monthly.absent, AppColors.error),
    ];
    final attendance = monthly.attendanceRate;
    final punctuality = monthly.punctualityRate;

    return RoundedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: CustomPaint(
                  painter: _DonutPainter(slices),
                  child: Center(
                    child: SizedBox(
                      width: 78,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            attendance == null ? '—' : _percent(attendance),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Asistencia',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.label,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (punctuality != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Punt. ${_percent(punctuality)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.label,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (final slice in slices) _LegendRow(slice: slice),
                  ],
                ),
              ),
            ],
          ),
          if (monthly.isMinistry) ...[
            const SizedBox(height: 14),
            Text(
              '${monthly.completedRehearsals ?? 0} de ${monthly.totalRehearsals} ensayos · ${monthly.totalMembers ?? 0} miembros',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.label,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _percent(double rate) =>
      '${(rate <= 1 ? rate * 100 : rate).round().clamp(0, 100)}%';
}

class _Slice {
  const _Slice(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice});

  final _Slice slice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: slice.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              slice.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${slice.value}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.slices);

  final List<_Slice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 16.0;
    final radius = size.shortestSide / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.inputFill;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = slice.value / total * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = slice.color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    if (oldDelegate.slices.length != slices.length) return true;
    for (var i = 0; i < slices.length; i++) {
      if (oldDelegate.slices[i].value != slices[i].value ||
          oldDelegate.slices[i].color != slices[i].color) {
        return true;
      }
    }
    return false;
  }
}
