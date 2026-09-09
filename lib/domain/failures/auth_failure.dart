sealed class AuthFailure {
  const AuthFailure(this.message);

  final String message;
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure()
      : super(
          'Su correo o contraseña no es correcta. Si no recuerda su contraseña, '
          'puede restablecerla ahora.',
        );
}

class EmptyCredentialsFailure extends AuthFailure {
  const EmptyCredentialsFailure()
      : super('Ingresa tu correo y contraseña para continuar.');
}

class NetworkFailure extends AuthFailure {
  const NetworkFailure()
      : super('No pudimos conectar. Intenta de nuevo más tarde.');
}
