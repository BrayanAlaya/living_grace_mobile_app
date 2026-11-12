import '../../domain/entities/user_role.dart';

class TokenResponseDto {
  const TokenResponseDto({
    required this.accessToken,
    this.tokenType = 'bearer',
    this.role = UserRole.user,
    this.mustChangePassword = false,
  });

  final String accessToken;
  final String tokenType;
  final UserRole role;
  final bool mustChangePassword;

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) {
    return TokenResponseDto(
      accessToken: json['access_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'bearer',
      role: UserRole.fromId(json['idRol']),
      mustChangePassword: json['must_change_password'] == true,
    );
  }
}
