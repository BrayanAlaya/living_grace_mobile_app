import '../models/rehearsal_schedule_dto.dart';

abstract interface class RehearsalRemoteDataSource {
  Future<List<MinistryOptionDto>> listMinistries();

  Future<List<MinistryMemberDto>> listMembers(int ministryId);

  Future<void> create(RehearsalCreateDto request);
}
