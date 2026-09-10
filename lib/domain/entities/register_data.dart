class RegisterData {
  const RegisterData({
    required this.displayName,
    required this.identifier,
    required this.password,
    required this.confirmPassword,
  });

  final String displayName;
  final String identifier;
  final String password;
  final String confirmPassword;
}
