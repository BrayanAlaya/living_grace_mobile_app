import '../entities/rehearsal_draft.dart';
import '../failures/rehearsal_failure.dart';

/// Contrato para armar, crear y actualizar un ensayo.
abstract interface class RehearsalRepository {
  Future<({List<MinistryOption>? ministries, RehearsalFailure? failure})>
  listMinistries();

  Future<({List<MinistryMember>? members, RehearsalFailure? failure})>
  listMembers(
    int ministryId, {
    MembershipStatus status = MembershipStatus.active,
  });

  Future<RehearsalFailure?> updateMemberStatus(
    int ministryId,
    int membershipId,
    MembershipStatus status,
  );

  Future<RehearsalFailure?> create(RehearsalDraft draft);

  Future<RehearsalFailure?> update(int rehearsalId, RehearsalDraft draft);
}
