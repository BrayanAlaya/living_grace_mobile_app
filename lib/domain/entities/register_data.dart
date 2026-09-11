class RegisterData {
  const RegisterData({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.birthDate,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String birthDate;
  final String email;
  final String password;
  final String confirmPassword;
}
