import 'dart:convert';

import '../domain/entities/user.dart';
import '../domain/entities/user_role.dart';

/// S — Single Responsibility: solo convierte el token/identificador en User.
class LoginUserMapper {
  User fromLogin({
    required String identifier,
    required String accessToken,
    UserRole role = UserRole.admin,
  }) {
    final claims = _decodeJwtPayload(accessToken);
    final email = _stringClaim(claims, const ['email']) ?? identifier;
    final displayName =
        _stringClaim(claims, const ['name', 'full_name']) ??
        (identifier.contains('@') ? identifier.split('@').first : email);
    final id =
        _stringClaim(claims, const ['sub', 'id', 'user_id']) ?? identifier;

    return User(id: id, email: email, displayName: displayName, role: role);
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) return json;
    } catch (_) {
      return null;
    }
    return null;
  }

  String? _stringClaim(Map<String, dynamic>? claims, List<String> keys) {
    if (claims == null) return null;
    for (final key in keys) {
      final value = claims[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
