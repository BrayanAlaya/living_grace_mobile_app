sealed class RehearsalRemoteException implements Exception {
  const RehearsalRemoteException();
}

class RehearsalUnauthorizedException extends RehearsalRemoteException {
  const RehearsalUnauthorizedException();
}

class RehearsalNetworkException extends RehearsalRemoteException {
  const RehearsalNetworkException([this.cause]);

  final Object? cause;
}

class RehearsalServerException extends RehearsalRemoteException {
  const RehearsalServerException(this.statusCode, [this.message]);

  final int statusCode;
  final String? message;
}

class RehearsalParseException extends RehearsalRemoteException {
  const RehearsalParseException();
}
