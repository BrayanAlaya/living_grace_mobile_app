/// Errores de la capa de datos; el repositorio los traduce a AuthFailure.
sealed class AuthRemoteException implements Exception {
  const AuthRemoteException();
}

class AuthUnauthorizedException extends AuthRemoteException {
  const AuthUnauthorizedException();
}

class AuthValidationException extends AuthRemoteException {
  const AuthValidationException([this.message]);

  final String? message;
}

class AuthServerException extends AuthRemoteException {
  const AuthServerException(this.statusCode);

  final int statusCode;
}

class AuthNetworkException extends AuthRemoteException {
  const AuthNetworkException([this.cause]);

  final Object? cause;
}
