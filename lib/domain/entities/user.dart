import 'user_role.dart';

class User {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.role = UserRole.admin,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
}
