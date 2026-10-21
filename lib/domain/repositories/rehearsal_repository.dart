import '../entities/rehearsal_draft.dart';
import '../failures/rehearsal_failure.dart';

/// Contrato para armar y crear un ensayo.
abstract interface class RehearsalRepository {
  Future<({List<MinistryOption>? ministries, RehearsalFailure? failure})>
  listMinistries();

  Future<({List<MinistryMember>? members, RehearsalFailure? failure})>
  listMembers(int ministryId);

  Future<RehearsalFailure?> create(RehearsalDraft draft);
}
