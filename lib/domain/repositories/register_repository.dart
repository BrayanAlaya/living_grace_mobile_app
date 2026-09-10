import '../entities/register_data.dart';
import '../entities/user.dart';
import '../failures/register_failure.dart';

/// Contrato de registro (Dependency Inversion).
abstract interface class RegisterRepository {
  Future<({User? user, RegisterFailure? failure})> register(RegisterData data);
}
