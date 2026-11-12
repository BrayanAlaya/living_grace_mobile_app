import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:living_grace/attendance/attendance_qr.dart';
import 'package:living_grace/dashboard/dashboard.dart';
import 'package:living_grace/data/session/in_memory_token_store.dart';
import 'package:living_grace/rehearsals/rehearsal.dart';
import 'package:living_grace/rehearsals/rehearsal_api.dart';

void main() {
  final rehearsal = Rehearsal(
    id: 7,
    name: 'Ensayo general',
    description: null,
    ministryId: 1,
    ministryName: 'Alabanza',
    leaderName: 'Luis Rey',
    startAt: DateTime(2026, 11, 14, 17),
    endAt: DateTime(2026, 11, 14, 19),
    toleranceMinutes: 10,
  );

  test('crea la sesión QR y registra el check-in', () async {
    final store = InMemoryTokenStore();
    await store.saveAccessToken('abc');
    final calls = <String>[];

    final client = MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      if (request.method == 'POST' &&
          request.url.path == '/rehearsals/7/qr-sessions') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['opens_at'], isNotEmpty);
        expect(body['expires_at'], isNotEmpty);
        return http.Response(
          jsonEncode({
            'id': 3,
            'rehearsal_id': 7,
            'check_in_url': 'https://api.test/check-in?token=qr-7',
            'opens_at': '2026-11-14T22:00:00Z',
            'expires_at': '2026-11-15T00:00:00Z',
          }),
          201,
        );
      }
      if (request.method == 'POST' &&
          request.url.path == '/attendance/check-in') {
        expect(jsonDecode(request.body), {'token': 'qr-7'});
        return http.Response(
          jsonEncode({
            'rehearsal_id': 7,
            'attendance_status': 'ON_TIME',
            'arrival_at': '2026-11-14T22:05:00Z',
          }),
          201,
        );
      }
      return http.Response('no', 404);
    });

    final api = RehearsalApi(tokenStore: store, client: client);

    final qr = await api.createQrSession(rehearsal);
    expect(qr.payload, 'https://api.test/check-in?token=qr-7');

    final checkIn = await api.checkIn(
      rehearsal: rehearsal,
      token: qr.payload,
    );
    expect(checkIn.status, AttendanceStatus.present);
    expect(calls, [
      'POST /rehearsals/7/qr-sessions',
      'POST /attendance/check-in',
    ]);
  });

  test('el check-in también acepta 200 si ya existía', () async {
    final store = InMemoryTokenStore();
    await store.saveAccessToken('abc');
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'rehearsal_id': 7,
          'attendance_status': 'ON_TIME',
          'arrival_at': '2026-11-14T22:05:00Z',
        }),
        200,
      );
    });

    final checkIn = await RehearsalApi(
      tokenStore: store,
      client: client,
    ).checkIn(rehearsal: rehearsal, token: 'qr-7');
    expect(checkIn.status, AttendanceStatus.present);
  });

  test('el check-in 409 indica que ya estaba registrada', () async {
    final store = InMemoryTokenStore();
    await store.saveAccessToken('abc');
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({'detail': 'Attendance already registered.'}),
        409,
      );
    });

    expect(
      () => RehearsalApi(
        tokenStore: store,
        client: client,
      ).checkIn(rehearsal: rehearsal, token: 'qr-7'),
      throwsA(
        isA<AttendanceCheckInException>().having(
          (error) => error.message,
          'message',
          'La asistencia ya estaba registrada.',
        ),
      ),
    );
  });

  test('saca el token de la URL del QR', () {
    expect(
      checkInTokenFromQr('https://api.test/attendance/check-in?token=abc-9'),
      'abc-9',
    );
    expect(checkInTokenFromQr('abc-9'), 'abc-9');
  });

  test('parsea recent_attendance del dashboard', () {
    final snapshot = DashboardSnapshot.fromJson({
      'selected_ministry_id': 1,
      'profile': {
        'user_id': 4,
        'display_name': 'Ana Paz',
        'account_status': 'ACTIVE',
        'is_global_admin': false,
        'memberships': [
          {
            'ministry_member_id': 8,
            'ministry_id': 1,
            'ministry_name': 'Alabanza',
            'functions': ['Voz'],
          },
        ],
      },
      'monthly_attendance': {
        'month': '2026-11',
        'timezone': 'America/Bogota',
        'total_completed_assigned_rehearsals': 4,
        'on_time': 2,
        'late': 1,
        'absent': 1,
        'justified': 0,
        'unresolved': 0,
        'attendance_rate': 0.75,
        'punctuality_rate': 0.5,
      },
      'recent_attendance': [
        {
          'rehearsal_id': 9,
          'ministry': {'id': 1, 'name': 'Alabanza'},
          'rehearsal_date': '2026-11-08',
          'start_at': '2026-11-08T22:00:00Z',
          'end_at': '2026-11-09T00:00:00Z',
          'attendance_status': 'LATE',
          'arrival_at': '2026-11-08T22:20:00Z',
        },
      ],
      'next_rehearsal': {
        'rehearsal_id': 11,
        'ministry': {'id': 1, 'name': 'Alabanza'},
        'name': 'Ensayo General',
        'description': null,
        'start_at': '2026-11-14T22:00:00Z',
        'end_at': '2026-11-15T00:00:00Z',
        'tolerance_minutes': 10,
      },
      'upcoming_rehearsals': [],
    });

    expect(snapshot.recentAttendance.single.status, AttendanceStatus.late);
    expect(snapshot.recentAttendance.single.title, 'Alabanza');
    expect(
      snapshot.recentAttendance.single.rehearsalDate,
      DateTime(2026, 11, 8),
    );
    expect(snapshot.recentAttendance.single.displayDate, DateTime(2026, 11, 8));
    expect(snapshot.nextRehearsal?.name, 'Ensayo General');
    expect(snapshot.nextRehearsal?.id, 11);
    expect(snapshot.monthly?.onTime, 2);
    expect(snapshot.monthly?.timezone, 'America/Bogota');
    expect(snapshot.monthly?.totalCompleted, 4);
    expect(snapshot.monthly?.unresolved, 0);
    expect(snapshot.monthly?.attendanceRate, 0.75);
    expect(
      MonthlyAttendance.fromJson({
        'month': '2026-11',
        'on_time': 4,
        'late': 0,
        'absent': 0,
        'justified': 0,
        'attendance_rate': 100,
        'punctuality_rate': 100,
      }).attendanceRate,
      1.0,
    );
    expect(
      MonthlyAttendance.fromJson({
        'month': '2026-11',
        'on_time': 4,
        'late': 0,
        'absent': 0,
        'justified': 0,
        'attendance_rate': 100,
        'punctuality_rate': 80,
      }).punctualityRate,
      0.8,
    );
    expect(snapshot.profile?.displayName, 'Ana Paz');
    expect(snapshot.profile?.accountStatus, 'ACTIVE');
    expect(snapshot.profile?.memberships.single.ministryName, 'Alabanza');
    expect(snapshot.rehearsalPreview.single.id, 11);
  });

  test('parsea ministry_attendance del administrador', () {
    final snapshot = DashboardSnapshot.fromJson({
      'selected_ministry_id': 1,
      'profile': {
        'user_id': 1,
        'display_name': 'Ana Admin',
        'account_status': 'ACTIVE',
        'is_global_admin': true,
        'memberships': [],
      },
      'ministry_attendance': {
        'month': '2026-11',
        'timezone': 'America/Lima',
        'total_rehearsals': 10,
        'completed_rehearsals': 9,
        'total_members': 7,
        'total_attendance_records': 28,
        'on_time': 6,
        'late': 0,
        'absent': 0,
        'justified': 0,
        'unresolved': 22,
        'attendance_rate': 100.0,
        'punctuality_rate': 100.0,
      },
      'recent_attendance': [],
      'next_rehearsal': null,
      'upcoming_rehearsals': [],
    });

    expect(snapshot.profile?.isGlobalAdmin, isTrue);
    expect(snapshot.monthly?.isMinistry, isTrue);
    expect(snapshot.monthly?.timezone, 'America/Lima');
    expect(snapshot.monthly?.totalRehearsals, 10);
    expect(snapshot.monthly?.completedRehearsals, 9);
    expect(snapshot.monthly?.totalCompleted, 9);
    expect(snapshot.monthly?.totalMembers, 7);
    expect(snapshot.monthly?.totalRecords, 28);
    expect(snapshot.monthly?.onTime, 6);
    expect(snapshot.monthly?.unresolved, 22);
    expect(snapshot.monthly?.attendanceRate, 1);
    expect(snapshot.monthly?.punctualityRate, 1);
  });

  test('el mensaje de puntualidad usa inicio y tolerancia', () {
    final start = DateTime(2026, 11, 14, 17);
    expect(
      attendanceTimingMessage(
        startAt: start,
        toleranceMinutes: 10,
        scannedAt: start.add(const Duration(minutes: 9)),
      ),
      'Llegaste a tiempo.',
    );
    expect(
      attendanceTimingMessage(
        startAt: start,
        toleranceMinutes: 10,
        scannedAt: start.add(const Duration(minutes: 11)),
      ),
      'Llegaste tarde.',
    );
  });
}
