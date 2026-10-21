import '../../domain/entities/user_profile.dart';

class ProfileMembershipDto {
  const ProfileMembershipDto({
    required this.ministry,
    this.functions = const [],
  });

  final String ministry;
  final List<String> functions;

  factory ProfileMembershipDto.fromJson(Map<String, dynamic> json) {
    final ministry = json['ministry'];
    if (ministry is! String || ministry.trim().isEmpty) {
      throw const FormatException('ProfileMembership');
    }

    return ProfileMembershipDto(
      ministry: ministry.trim(),
      functions: _strings(json['functions']),
    );
  }

  ProfileMembership toDomain() {
    return ProfileMembership(ministry: ministry, functions: functions);
  }
}

class UserProfileDto {
  const UserProfileDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
    this.phone,
    this.birthDate,
    this.memberships = const [],
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? birthDate;
  final String createdAt;
  final List<ProfileMembershipDto> memberships;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'];
    final lastName = json['last_name'];
    final email = json['email'];
    final createdAt = json['created_at'];

    if (firstName is! String ||
        lastName is! String ||
        email is! String ||
        createdAt is! String) {
      throw const FormatException('UserProfile');
    }

    return UserProfileDto(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      phone: _optionalText(json['phone']),
      birthDate: _optionalText(json['birth_date']),
      createdAt: createdAt,
      memberships: _memberships(json['memberships']),
    );
  }

  UserProfile toDomain() {
    return UserProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      birthDate: birthDate,
      createdAt: createdAt,
      memberships: [for (final item in memberships) item.toDomain()],
    );
  }
}

String? _optionalText(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

List<String> _strings(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];
}

List<ProfileMembershipDto> _memberships(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map)
        ProfileMembershipDto.fromJson(Map<String, dynamic>.from(item)),
  ];
}
