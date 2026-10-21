/// Rol de sesión. `1` es admin y `2` es usuario.
///
/// Provisional: si el login no trae `idRol`, se asume admin para pruebas.
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
      2 => UserRole.user,
      _ => UserRole.admin,
    };
  }
}
