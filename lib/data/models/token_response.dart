class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    this.tokenType = 'bearer',
  });

  final String accessToken;
  final String tokenType;

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
    );
  }
}
