sealed class ProfileFailure {
  const ProfileFailure(this.message);

  final String message;
}

class ProfileUnauthorizedFailure extends ProfileFailure {
  const ProfileUnauthorizedFailure()
    : super('Tu sesión expiró. Vuelve a iniciar sesión.');
}

class ProfileNetworkFailure extends ProfileFailure {
  const ProfileNetworkFailure()
    : super('No pudimos cargar tu perfil. Intenta de nuevo.');
}

class ProfileUnexpectedFailure extends ProfileFailure {
  const ProfileUnexpectedFailure([
    super.message = 'No pudimos cargar tu perfil.',
  ]);
}
