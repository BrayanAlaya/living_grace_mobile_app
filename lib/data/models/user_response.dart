import '../../domain/entities/user.dart';

class UserResponse {
  const UserResponse({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.birthDate,
    this.deletedAt,
  });

  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? birthDate;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String?,
      birthDate: json['birth_date'] as String?,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      deletedAt: json['deleted_at'] as String?,
    );
  }

  User toDomain() {
    final displayName = '$firstName $lastName'.trim();
    return User(
      id: id.toString(),
      email: email,
      displayName: displayName.isEmpty ? username : displayName,
    );
  }
}
