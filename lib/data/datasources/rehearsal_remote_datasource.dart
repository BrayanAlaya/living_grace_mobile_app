import '../../domain/entities/rehearsal_draft.dart';
import '../models/rehearsal_schedule_dto.dart';

abstract interface class RehearsalRemoteDataSource {
  Future<List<MinistryOptionDto>> listMinistries();

  Future<List<MinistryMemberDto>> listMembers(
    int ministryId, {
    MembershipStatus status = MembershipStatus.active,
  });

  Future<void> updateMemberStatus(
    int ministryId,
    int membershipId,
    MembershipStatus status,
  );

  Future<void> create(RehearsalCreateDto request);

  Future<void> update(int rehearsalId, RehearsalUpdateDto request);
}
