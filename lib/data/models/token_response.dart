import '../../domain/entities/user_role.dart';

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    this.tokenType = 'bearer',
    this.role = UserRole.user,
    this.mustChangePassword = false,
  });

  final String accessToken;
  final String tokenType;
  final UserRole role;
  final bool mustChangePassword;

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException('TokenResponse sin access_token');
    }

    return TokenResponse(
      accessToken: accessToken,
      tokenType: (json['token_type'] as String?)?.trim().isNotEmpty == true
          ? json['token_type'] as String
          : 'bearer',
      role: UserRole.fromId(json['idRol']),
      mustChangePassword: json['must_change_password'] == true,
    );
  }
}
