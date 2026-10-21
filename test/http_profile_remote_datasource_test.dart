import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:living_grace/data/datasources/http_profile_remote_datasource.dart';
import 'package:living_grace/data/datasources/profile_remote_exceptions.dart';
import 'package:living_grace/data/session/in_memory_token_store.dart';

void main() {
  test('GET /users/me envía el bearer y lee el perfil', () async {
    final store = InMemoryTokenStore();
    await store.saveAccessToken('abc');

    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/users/me');
      expect(request.headers['authorization'], 'Bearer abc');
      return http.Response(
        jsonEncode({
          'first_name': 'Jhanpool',
          'last_name': 'Curay',
          'email': 'jhanpool.curay17@outlook.com',
          'phone': '980985755',
          'birth_date': '1999-09-23',
          'created_at': '2026-08-12T12:00:00Z',
          'memberships': [
            {
              'ministry': 'Alabanza',
              'functions': ['Guitarrista'],
            },
          ],
        }),
        200,
      );
    });

    final dataSource = HttpProfileRemoteDataSource(
      tokenStore: store,
      client: client,
      baseUrl: 'https://api.test',
    );

    final profile = await dataSource.getMine();
    expect(profile.email, 'jhanpool.curay17@outlook.com');
    expect(profile.memberships.single.functions, ['Guitarrista']);
  });

  test('sin token no llama a la red', () async {
    final dataSource = HttpProfileRemoteDataSource(
      tokenStore: InMemoryTokenStore(),
      client: MockClient((_) async => http.Response('no', 500)),
      baseUrl: 'https://api.test',
    );

    expect(dataSource.getMine(), throwsA(isA<ProfileUnauthorizedException>()));
  });
}
