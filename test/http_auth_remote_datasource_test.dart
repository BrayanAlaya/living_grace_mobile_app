import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:living_grace/data/datasources/http_auth_remote_datasource.dart';

void main() {
  test('POST /users/{id}/reset-password devuelve temporary_password', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/users/4/reset-password');
      expect(request.headers['authorization'], 'Bearer abc');
      expect(request.headers['content-type'], contains('application/json'));
      return http.Response(
        jsonEncode({
          'temporary_password': 'Grace-tmp-9',
          'must_change_password': true,
        }),
        200,
      );
    });

    final dataSource = HttpAuthRemoteDataSource(
      client: client,
      baseUrl: 'https://api.test',
    );

    final password = await dataSource.resetPassword(
      accessToken: 'abc',
      userId: 4,
    );
    expect(password, 'Grace-tmp-9');
  });

  test('POST /auth/change-password envía ambas claves', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/auth/change-password');
      expect(request.headers['authorization'], 'Bearer abc');
      expect(jsonDecode(request.body), {
        'current_password': 'Temp#1',
        'new_password': 'NuevaClave8',
      });
      return http.Response('', 204);
    });

    final dataSource = HttpAuthRemoteDataSource(
      client: client,
      baseUrl: 'https://api.test',
    );

    await dataSource.changePassword(
      accessToken: 'abc',
      currentPassword: 'Temp#1',
      newPassword: 'NuevaClave8',
    );
  });
}
