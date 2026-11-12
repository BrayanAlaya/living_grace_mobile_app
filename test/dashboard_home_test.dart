import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:living_grace/attendance/attendance_qr.dart';
import 'package:living_grace/dashboard/dashboard.dart';
import 'package:living_grace/dashboard/dashboard_api.dart';
import 'package:living_grace/data/session/in_memory_token_store.dart';
import 'package:living_grace/domain/entities/rehearsal_draft.dart';
import 'package:living_grace/presentation/pages/home_page.dart';
import 'package:living_grace/rehearsals/rehearsal.dart';
import 'package:living_grace/rehearsals/rehearsal_api.dart';

void main() {
  test('GET /dashboard/me envía ministry_id', () async {
    final store = InMemoryTokenStore();
    await store.saveAccessToken('abc');
    late Uri seen;
    final client = MockClient((request) async {
      seen = request.url;
      return http.Response(
        jsonEncode({
          'selected_ministry_id': 2,
          'profile': {
            'user_id': 4,
            'display_name': 'Ana Paz',
            'account_status': 'ACTIVE',
            'is_global_admin': false,
            'memberships': [],
          },
          'monthly_attendance': {
            'month': '2026-11',
            'timezone': 'America/Bogota',
            'total_completed_assigned_rehearsals': 0,
            'on_time': 0,
            'late': 0,
            'absent': 0,
            'attendance_rate': null,
            'punctuality_rate': null,
          },
          'recent_attendance': [],
          'next_rehearsal': null,
          'upcoming_rehearsals': [],
        }),
        200,
      );
    });

    await DashboardApi(tokenStore: store, client: client).fetch(ministryId: 2);
    expect(seen.path, '/dashboard/me');
    expect(seen.queryParameters['ministry_id'], '2');
  });

  testWidgets('el selector de ministerios recarga el dashboard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _FakeDashboardApi();
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          name: 'Ana',
          onOpenSettings: () {},
          onDestinationSelected: (_) {},
          rehearsalApi: _EmptyRehearsalApi(),
          dashboardApi: api,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ministerio'), findsOneWidget);
    expect(find.text('Alabanza'), findsWidgets);
    expect(find.text('Danza'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Presente'), findsOneWidget);
    expect(find.text('Tarde'), findsWidgets);
    expect(find.text('Ausente'), findsOneWidget);
    expect(find.text('Justificado'), findsNothing);
    expect(find.text('Sin resolver'), findsNothing);
    expect(find.text('Noviembre 2026'), findsNothing);
    expect(find.text('Asistencias'), findsOneWidget);
    expect(find.text('Ensayo General'), findsOneWidget);
    expect(api.ministryIds, [null]);

    await tester.tap(find.byKey(const ValueKey('dashboard-ministry-2')));
    await tester.pumpAndSettle();
    expect(api.ministryIds, [null, 2]);
  });

  testWidgets('el admin ve el ministerio y no la lista de asistencias', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          name: 'Ana',
          onOpenSettings: () {},
          onDestinationSelected: (_) {},
          rehearsalApi: _EmptyRehearsalApi(),
          dashboardApi: _AdminDashboardApi(),
          canManageRehearsals: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('20%'), findsOneWidget);
    expect(find.text('10 de 10 ensayos · 9 miembros'), findsOneWidget);
    expect(find.text('Ausente'), findsOneWidget);
    expect(find.text('Sin resolver'), findsNothing);
    expect(find.text('Asistencias'), findsNothing);
    expect(find.text('Ensayo General'), findsOneWidget);
  });

  testWidgets('el menú lateral incluye ensayos y asistencias', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          name: 'Ana',
          onOpenSettings: () {},
          onDestinationSelected: (_) {},
          rehearsalApi: _EmptyRehearsalApi(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Inicio'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Ensayos'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Asistencias'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Ajustes'), findsOneWidget);
  });
}

class _EmptyRehearsalApi extends RehearsalApi {
  _EmptyRehearsalApi() : super(tokenStore: InMemoryTokenStore());

  @override
  Future<List<Rehearsal>> fetchUpcoming() async => const [];

  @override
  Future<List<Rehearsal>> fetchAll() async => const [];

  @override
  Future<({List<Rehearsal> items, int total})> fetchPage({
    int limit = 20,
    int offset = 0,
    int? ministryId,
  }) async => (items: const <Rehearsal>[], total: 0);

  @override
  Future<List<MinistryOption>> listMinistries() async => const [];
}

class _AdminDashboardApi extends DashboardApi {
  _AdminDashboardApi() : super(tokenStore: InMemoryTokenStore());

  @override
  Future<DashboardSnapshot> fetch({int? ministryId}) async {
    return DashboardSnapshot(
      selectedMinistryId: 1,
      profile: const DashboardProfile(
        userId: 1,
        displayName: 'Ana Admin',
        isGlobalAdmin: true,
        memberships: [
          DashboardMembership(
            ministryMemberId: 1,
            ministryId: 1,
            ministryName: 'Alabanza',
          ),
        ],
      ),
      monthly: const MonthlyAttendance(
        month: '2026-11',
        timezone: 'America/Lima',
        onTime: 6,
        late: 0,
        absent: 24,
        totalCompleted: 10,
        totalRehearsals: 10,
        completedRehearsals: 10,
        totalMembers: 9,
        totalRecords: 30,
        attendanceRate: 0.2,
        punctualityRate: 1,
      ),
      nextRehearsal: Rehearsal(
        id: 11,
        name: 'Ensayo General',
        description: null,
        ministryId: 1,
        ministryName: 'Alabanza',
        leaderName: '',
        startAt: DateTime(2026, 11, 14, 17),
        endAt: DateTime(2026, 11, 14, 19),
        toleranceMinutes: 10,
      ),
      recentAttendance: [
        RecentAttendance(
          rehearsalId: 9,
          title: 'Alabanza',
          startAt: DateTime(2026, 11, 8, 17),
          endAt: DateTime(2026, 11, 8, 19),
          status: AttendanceStatus.present,
        ),
      ],
    );
  }
}

class _FakeDashboardApi extends DashboardApi {
  _FakeDashboardApi() : super(tokenStore: InMemoryTokenStore());

  final ministryIds = <int?>[];

  @override
  Future<DashboardSnapshot> fetch({int? ministryId}) async {
    ministryIds.add(ministryId);
    final selected = ministryId ?? 1;
    return DashboardSnapshot(
      selectedMinistryId: selected,
      profile: const DashboardProfile(
        userId: 4,
        displayName: 'Ana Paz',
        isGlobalAdmin: false,
        memberships: [
          DashboardMembership(
            ministryMemberId: 1,
            ministryId: 1,
            ministryName: 'Alabanza',
          ),
          DashboardMembership(
            ministryMemberId: 2,
            ministryId: 2,
            ministryName: 'Danza',
          ),
        ],
      ),
      monthly: const MonthlyAttendance(
        month: '2026-11',
        timezone: 'America/Bogota',
        onTime: 2,
        late: 1,
        absent: 1,
        totalCompleted: 4,
        attendanceRate: 0.75,
        punctualityRate: 0.5,
      ),
      nextRehearsal: Rehearsal(
        id: 11,
        name: 'Ensayo General',
        description: null,
        ministryId: selected,
        ministryName: selected == 1 ? 'Alabanza' : 'Danza',
        leaderName: 'Luis Rey',
        startAt: DateTime(2026, 11, 14, 17),
        endAt: DateTime(2026, 11, 14, 19),
        toleranceMinutes: 10,
      ),
      recentAttendance: [
        RecentAttendance(
          rehearsalId: 9,
          title: selected == 1 ? 'Alabanza' : 'Danza',
          startAt: DateTime(2026, 11, 8, 17),
          endAt: DateTime(2026, 11, 8, 19),
          status: AttendanceStatus.late,
        ),
      ],
    );
  }
}
