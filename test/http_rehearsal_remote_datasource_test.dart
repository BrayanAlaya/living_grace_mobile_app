import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:living_grace/data/datasources/http_rehearsal_remote_datasource.dart';
import 'package:living_grace/data/models/rehearsal_schedule_dto.dart';
import 'package:living_grace/data/session/in_memory_token_store.dart';
import 'package:living_grace/domain/entities/rehearsal_draft.dart';

void main() {
  test('crea el ensayo con el cuerpo del contrato', () async {
    final store = InMemoryTokenStore();
    await store.saveAccessToken('abc');

    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/rehearsals');
      expect(request.headers['authorization'], 'Bearer abc');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['ministry_id'], 3);
      expect(body['name'], 'Ensayo general');
      expect(body['description'], isNull);
      expect(body['tolerance_minutes'], 10);
      expect(body['ministry_member_ids'], [8, 9]);
      expect(body['start_at'], isA<String>());
      expect(body['end_at'], isA<String>());
      return http.Response('{"id": 1}', 201);
    });

    final dataSource = HttpRehearsalRemoteDataSource(
      tokenStore: store,
      client: client,
      baseUrl: 'https://api.test',
    );

    await dataSource.create(
      RehearsalCreateDto.fromDraft(
        RehearsalDraft(
          ministryId: 3,
          name: 'Ensayo general',
          startAt: DateTime.utc(2026, 8, 12, 19),
          endAt: DateTime.utc(2026, 8, 12, 21),
          toleranceMinutes: 10,
          ministryMemberIds: const [8, 9],
        ),
      ),
    );
  });

  test('lee ministerios y miembros', () async {
    final store = InMemoryTokenStore();
    await store.saveAccessToken('abc');
    var calls = 0;

    final client = MockClient((request) async {
      calls++;
      if (request.url.path == '/ministries/registration-fields') {
        return http.Response(
          jsonEncode([
            {
              'id': 2,
              'name': 'Alabanza',
              'description': null,
              'functions': ['Voz'],
              'function_options': [
                {'id': 1, 'name': 'Voz'},
              ],
            },
          ]),
          200,
        );
      }
      expect(request.url.path, '/ministries/2/members');
      return http.Response(
        jsonEncode({
          'ministry_id': 2,
          'members': [
            {
              'ministry_member_id': 8,
              'user_id': 4,
              'first_name': 'Ana',
              'last_name': 'Paz',
              'functions': ['Voz'],
            },
          ],
        }),
        200,
      );
    });

    final dataSource = HttpRehearsalRemoteDataSource(
      tokenStore: store,
      client: client,
      baseUrl: 'https://api.test',
    );

    final ministries = await dataSource.listMinistries();
    final members = await dataSource.listMembers(2);

    expect(calls, 2);
    expect(ministries.single.name, 'Alabanza');
    expect(members.single.ministryMemberId, 8);
    expect(members.single.toDomain().fullName, 'Ana Paz');
  });

  test('actualiza el ensayo sin enviar el ministerio', () async {
    final store = InMemoryTokenStore();
    await store.saveAccessToken('abc');

    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/rehearsals/7');
      expect(request.headers['authorization'], 'Bearer abc');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.containsKey('ministry_id'), isFalse);
      expect(body['name'], 'Ensayo de voces');
      expect(body['description'], 'Voces');
      expect(body['tolerance_minutes'], 10);
      expect(body['ministry_member_ids'], [8]);
      return http.Response('{"id": 7}', 200);
    });

    final dataSource = HttpRehearsalRemoteDataSource(
      tokenStore: store,
      client: client,
      baseUrl: 'https://api.test',
    );

    await dataSource.update(
      7,
      RehearsalUpdateDto.fromDraft(
        RehearsalDraft(
          ministryId: 3,
          name: 'Ensayo de voces',
          description: 'Voces',
          startAt: DateTime.utc(2026, 8, 12, 19),
          endAt: DateTime.utc(2026, 8, 12, 21),
          toleranceMinutes: 10,
          ministryMemberIds: const [8],
        ),
      ),
    );
  });
}
