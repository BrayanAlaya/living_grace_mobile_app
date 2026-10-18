class TokenResponseDto {
  const TokenResponseDto({
    required this.accessToken,
    this.tokenType = 'bearer',
  });

  final String accessToken;
  final String tokenType;

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) {
    return TokenResponseDto(
      accessToken: json['access_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'bearer',
    );
  }
}
