import '../../domain/entities/rehearsal_draft.dart';
import '../../domain/failures/rehearsal_failure.dart';
import '../../domain/repositories/rehearsal_repository.dart';
import '../datasources/rehearsal_remote_datasource.dart';
import '../datasources/rehearsal_remote_exceptions.dart';
import '../models/rehearsal_schedule_dto.dart';

class ApiRehearsalRepository implements RehearsalRepository {
  ApiRehearsalRepository({required this._remoteDataSource});

  final RehearsalRemoteDataSource _remoteDataSource;

  @override
  Future<({List<MinistryOption>? ministries, RehearsalFailure? failure})>
  listMinistries() async {
    try {
      final items = await _remoteDataSource.listMinistries();
      return (
        ministries: [for (final item in items) item.toDomain()],
        failure: null,
      );
    } on RehearsalRemoteException catch (error) {
      return (ministries: null, failure: _map(error));
    }
  }

  @override
  Future<({List<MinistryMember>? members, RehearsalFailure? failure})>
  listMembers(int ministryId) async {
    try {
      final items = await _remoteDataSource.listMembers(ministryId);
      return (
        members: [for (final item in items) item.toDomain()],
        failure: null,
      );
    } on RehearsalRemoteException catch (error) {
      return (members: null, failure: _map(error));
    }
  }

  @override
  Future<RehearsalFailure?> create(RehearsalDraft draft) async {
    try {
      await _remoteDataSource.create(RehearsalCreateDto.fromDraft(draft));
      return null;
    } on RehearsalRemoteException catch (error) {
      return _map(error);
    }
  }

  @override
  Future<RehearsalFailure?> update(
    int rehearsalId,
    RehearsalDraft draft,
  ) async {
    try {
      await _remoteDataSource.update(
        rehearsalId,
        RehearsalUpdateDto.fromDraft(draft),
      );
      return null;
    } on RehearsalRemoteException catch (error) {
      return _map(error);
    }
  }

  RehearsalFailure _map(RehearsalRemoteException error) {
    return switch (error) {
      RehearsalUnauthorizedException() => const RehearsalUnauthorizedFailure(),
      RehearsalNetworkException() => const RehearsalNetworkFailure(),
      RehearsalServerException(:final statusCode, :final message)
          when statusCode == 422 =>
        RehearsalValidationFailure(message ?? 'Revisa los datos del ensayo.'),
      RehearsalServerException() => const RehearsalNetworkFailure(),
      RehearsalParseException() => const RehearsalValidationFailure(
        'La respuesta del servidor no se pudo leer.',
      ),
    };
  }
}
