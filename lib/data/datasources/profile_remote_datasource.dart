import '../models/user_profile_dto.dart';

/// Origen remoto del perfil. La UI no conoce esta interfaz.
abstract interface class ProfileRemoteDataSource {
  Future<UserProfileDto> getMine();
}
