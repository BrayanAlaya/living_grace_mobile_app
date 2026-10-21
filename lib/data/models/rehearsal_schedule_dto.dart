import '../../domain/entities/rehearsal_draft.dart';

class MinistryOptionDto {
  const MinistryOptionDto({required this.id, required this.name});

  final int id;
  final String name;

  factory MinistryOptionDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! int || name is! String || name.trim().isEmpty) {
      throw const FormatException('MinistryRegistrationInfo');
    }
    return MinistryOptionDto(id: id, name: name.trim());
  }

  MinistryOption toDomain() => MinistryOption(id: id, name: name);
}

class MinistryMemberDto {
  const MinistryMemberDto({
    required this.ministryMemberId,
    required this.firstName,
    required this.lastName,
    this.functions = const [],
  });

  final int ministryMemberId;
  final String firstName;
  final String lastName;
  final List<String> functions;

  factory MinistryMemberDto.fromJson(Map<String, dynamic> json) {
    final id = json['ministry_member_id'];
    final firstName = json['first_name'];
    final lastName = json['last_name'];
    if (id is! int || firstName is! String || lastName is! String) {
      throw const FormatException('MinistryMemberInfo');
    }
    return MinistryMemberDto(
      ministryMemberId: id,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      functions: _strings(json['functions']),
    );
  }

  MinistryMember toDomain() {
    return MinistryMember(
      ministryMemberId: ministryMemberId,
      firstName: firstName,
      lastName: lastName,
      functions: functions,
    );
  }
}

class RehearsalCreateDto {
  const RehearsalCreateDto({
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
  final String startAt;
  final String endAt;
  final int toleranceMinutes;
  final List<int> ministryMemberIds;

  factory RehearsalCreateDto.fromDraft(RehearsalDraft draft) {
    final description = draft.description?.trim();
    return RehearsalCreateDto(
      ministryId: draft.ministryId,
      name: draft.name.trim(),
      description: description == null || description.isEmpty
          ? null
          : description,
      startAt: draft.startAt.toUtc().toIso8601String(),
      endAt: draft.endAt.toUtc().toIso8601String(),
      toleranceMinutes: draft.toleranceMinutes,
      ministryMemberIds: draft.ministryMemberIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ministry_id': ministryId,
      'name': name,
      'description': description,
      'start_at': startAt,
      'end_at': endAt,
      'tolerance_minutes': toleranceMinutes,
      'ministry_member_ids': ministryMemberIds,
    };
  }
}

List<String> _strings(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];
}
