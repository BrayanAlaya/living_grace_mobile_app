import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/data/datasources/profile_remote_datasource.dart';
import 'package:living_grace/data/datasources/profile_remote_exceptions.dart';
import 'package:living_grace/data/models/user_profile_dto.dart';
import 'package:living_grace/data/repositories/api_profile_repository.dart';
import 'package:living_grace/domain/failures/profile_failure.dart';
import 'package:living_grace/presentation/profile/profile_date_format.dart';
import 'package:living_grace/presentation/profile/profile_view_mapper.dart';

void main() {
  test('parsea UserProfile con nulos y membresías', () {
    final dto = UserProfileDto.fromJson({
      'first_name': 'Jhanpool',
      'last_name': 'Curay',
      'email': 'jhanpool.curay17@outlook.com',
      'phone': null,
      'birth_date': null,
      'created_at': '2026-08-12T12:00:00Z',
      'memberships': [
        {
          'ministry': 'Alabanza',
          'functions': ['Guitarrista'],
        },
      ],
    });

    final profile = dto.toDomain();
    expect(profile.fullName, 'Jhanpool Curay');
    expect(profile.phone, isNull);
    expect(profile.memberships.single.ministry, 'Alabanza');
    expect(profile.memberships.single.functions, ['Guitarrista']);
  });

  test('una fecha calendario no cambia de día', () {
    expect(
      ProfileDateFormat.calendarDate('1999-09-23'),
      '23 de Septiembre de 1999',
    );
  });

  test('sin teléfono ni usuario el valor vacío es un guion', () {
    final view = ProfileViewMapper.map(
      UserProfileDto.fromJson({
        'first_name': 'Ana',
        'last_name': 'Paz',
        'email': 'ana@livinggrace.com',
        'phone': null,
        'birth_date': null,
        'created_at': '2026-08-12T12:00:00',
      }).toDomain(),
    );

    expect(
      view.personal.firstWhere((field) => field.label == 'Teléfono').value,
      '—',
    );
    expect(view.role, isNull);
    expect(
      view.additional.map((field) => field.label),
      isNot(contains('Nombre de Usuario')),
    );
  });

  test('401 del origen remoto es sesión expirada', () async {
    final repository = ApiProfileRepository(
      remoteDataSource: _FakeProfileRemote(
        () async => throw const ProfileUnauthorizedException(),
      ),
    );

    final result = await repository.getMine();
    expect(result.profile, isNull);
    expect(result.failure, isA<ProfileUnauthorizedFailure>());
  });
}

class _FakeProfileRemote implements ProfileRemoteDataSource {
  _FakeProfileRemote(this._handler);

  final Future<UserProfileDto> Function() _handler;

  @override
  Future<UserProfileDto> getMine() => _handler();
}
