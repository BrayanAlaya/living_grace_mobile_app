import '../../domain/entities/user_profile.dart';
import '../../domain/failures/profile_failure.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../datasources/profile_remote_exceptions.dart';

/// Traduce GET /users/me al contrato de dominio.
class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({required this._remoteDataSource});

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<({UserProfile? profile, ProfileFailure? failure})> getMine() async {
    try {
      final dto = await _remoteDataSource.getMine();
      return (profile: dto.toDomain(), failure: null);
    } on ProfileUnauthorizedException {
      return (profile: null, failure: const ProfileUnauthorizedFailure());
    } on ProfileNetworkException {
      return (profile: null, failure: const ProfileNetworkFailure());
    } on ProfileRemoteException {
      return (profile: null, failure: const ProfileUnexpectedFailure());
    }
  }
}
