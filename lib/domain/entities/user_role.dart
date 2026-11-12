/// Rol residual del token. El panel admin usa `is_global_admin` de `/users/me`.
enum UserRole {
  admin,
  user;

  bool get isAdmin => this == UserRole.admin;

  static UserRole fromId(Object? raw) {
    final id = switch (raw) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value.trim()),
      _ => null,
    };

    return switch (id) {
      1 => UserRole.admin,
      _ => UserRole.user,
    };
  }
}
