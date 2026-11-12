class MinistryOption {
  const MinistryOption({required this.id, required this.name});

  final int id;
  final String name;
}

enum MembershipStatus {
  pending,
  active,
  inactive;

  String get apiValue => switch (this) {
    MembershipStatus.pending => 'PENDING',
    MembershipStatus.active => 'ACTIVE',
    MembershipStatus.inactive => 'INACTIVE',
  };

  String get label => switch (this) {
    MembershipStatus.pending => 'Pendiente',
    MembershipStatus.active => 'Activo',
    MembershipStatus.inactive => 'Inactivo',
  };

  static MembershipStatus fromApi(Object? raw) {
    return switch (raw) {
      'PENDING' => MembershipStatus.pending,
      'INACTIVE' => MembershipStatus.inactive,
      _ => MembershipStatus.active,
    };
  }
}

class MinistryMember {
  const MinistryMember({
    required this.ministryMemberId,
    required this.firstName,
    required this.lastName,
    this.userId,
    this.functions = const [],
    this.status = MembershipStatus.active,
  });

  final int ministryMemberId;
  final int? userId;
  final String firstName;
  final String lastName;
  final List<String> functions;
  final MembershipStatus status;

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

/// Datos con los que el formulario de alta se rellena para editar.
class RehearsalFormSeed {
  const RehearsalFormSeed({
    required this.rehearsalId,
    required this.ministryId,
    required this.ministryName,
    required this.name,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.toleranceMinutes,
    required this.members,
  });

  final int rehearsalId;
  final int ministryId;
  final String ministryName;
  final String name;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final int toleranceMinutes;
  final List<MinistryMember> members;

  List<int> get memberIds => [
    for (final member in members) member.ministryMemberId,
  ];
}
