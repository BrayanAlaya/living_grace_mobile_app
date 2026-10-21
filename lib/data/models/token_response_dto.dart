import '../../domain/entities/user_role.dart';

class TokenResponseDto {
  const TokenResponseDto({
    required this.accessToken,
    this.tokenType = 'bearer',
    this.role = UserRole.admin,
  });

  final String accessToken;
  final String tokenType;
  final UserRole role;

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) {
    return TokenResponseDto(
      accessToken: json['access_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'bearer',
      role: UserRole.fromId(json['idRol']),
    );
  }
}
