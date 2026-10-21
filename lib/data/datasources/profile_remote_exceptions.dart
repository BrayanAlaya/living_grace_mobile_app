sealed class ProfileRemoteException implements Exception {
  const ProfileRemoteException();
}

class ProfileUnauthorizedException extends ProfileRemoteException {
  const ProfileUnauthorizedException();
}

class ProfileNetworkException extends ProfileRemoteException {
  const ProfileNetworkException([this.cause]);

  final Object? cause;
}

class ProfileServerException extends ProfileRemoteException {
  const ProfileServerException(this.statusCode);

  final int statusCode;
}

class ProfileParseException extends ProfileRemoteException {
  const ProfileParseException();
}
