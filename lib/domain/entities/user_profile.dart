class ProfileMembership {
  const ProfileMembership({required this.ministry, this.functions = const []});

  final String ministry;
  final List<String> functions;
}

/// Perfil devuelto por GET /users/me.
class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
    this.phone,
    this.birthDate,
    this.memberships = const [],
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? birthDate;
  final String createdAt;
  final List<ProfileMembership> memberships;

  String get fullName => '$firstName $lastName'.trim();
}
