sealed class RehearsalFailure {
  const RehearsalFailure(this.message);

  final String message;
}

class RehearsalNetworkFailure extends RehearsalFailure {
  const RehearsalNetworkFailure()
    : super('No pudimos conectar. Intenta de nuevo.');
}

class RehearsalUnauthorizedFailure extends RehearsalFailure {
  const RehearsalUnauthorizedFailure()
    : super('Tu sesión expiró. Vuelve a iniciar sesión.');
}

class RehearsalValidationFailure extends RehearsalFailure {
  const RehearsalValidationFailure(super.message);
}
