import 'user_role.dart';

class User {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.role = UserRole.user,
    this.mustChangePassword = false,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final bool mustChangePassword;

  User copyWith({bool? mustChangePassword}) {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      role: role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}
