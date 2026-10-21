class MinistryOption {
  const MinistryOption({required this.id, required this.name});

  final int id;
  final String name;
}

class MinistryMember {
  const MinistryMember({
    required this.ministryMemberId,
    required this.firstName,
    required this.lastName,
    this.functions = const [],
  });

  final int ministryMemberId;
  final String firstName;
  final String lastName;
  final List<String> functions;

  String get fullName => '$firstName $lastName'.trim();
}

/// Cuerpo de POST /rehearsals.
class RehearsalDraft {
  const RehearsalDraft({
    required this.ministryId,
    required this.name,
    required this.startAt,
    required this.endAt,
    required this.ministryMemberIds,
    this.description,
    this.toleranceMinutes = 0,
  });

  final int ministryId;
  final String name;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final int toleranceMinutes;
  final List<int> ministryMemberIds;
}
