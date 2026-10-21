import '../entities/user_profile.dart';
import '../failures/profile_failure.dart';

/// Contrato de lectura del perfil (Dependency Inversion).
abstract interface class ProfileRepository {
  Future<({UserProfile? profile, ProfileFailure? failure})> getMine();
}
