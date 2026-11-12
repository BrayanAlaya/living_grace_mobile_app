import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/domain/entities/rehearsal_draft.dart';
import 'package:living_grace/domain/failures/rehearsal_failure.dart';
import 'package:living_grace/domain/repositories/rehearsal_repository.dart';
import 'package:living_grace/presentation/pages/ministry_members_page.dart';

void main() {
  testWidgets('filtra miembros y cambia cualquier estado', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _MembersRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: MinistryMembersPage(repository: repository, onBack: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Miembros'), findsOneWidget);
    expect(find.text('Buscar por nombre'), findsOneWidget);
    expect(repository.listedStatus, MembershipStatus.pending);
    expect(find.text('Ana Paz'), findsOneWidget);
    expect(find.text('Carlos Vega'), findsOneWidget);
    expect(find.text('Pendiente'), findsWidgets);
    expect(find.text('Luis Rey'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ana');
    await tester.pump();
    expect(find.text('Ana Paz'), findsOneWidget);
    expect(find.text('Carlos Vega'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(
      find.text('No hay miembros que coincidan con la búsqueda.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Carlos Vega'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('membership-ACTIVE')));
    await tester.pumpAndSettle();
    expect(repository.listedStatus, MembershipStatus.active);
    expect(find.text('Luis Rey'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('membership-PENDING')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ana Paz');
    await tester.pump();
    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige el estado de Ana Paz.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('set-membership-ACTIVE')));
    await tester.pumpAndSettle();

    expect(repository.updated, (2, 8, MembershipStatus.active));
    expect(find.text('Ana Paz quedó como activo.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Ana Paz'), findsNothing);
    expect(find.text('Carlos Vega'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('membership-ACTIVE')));
    await tester.pumpAndSettle();
    expect(find.text('Ana Paz'), findsOneWidget);
    expect(find.text('Luis Rey'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ana Paz');
    await tester.pump();
    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('set-membership-INACTIVE')));
    await tester.pumpAndSettle();
    expect(repository.updated, (2, 8, MembershipStatus.inactive));

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Ana Paz'), findsNothing);
    expect(find.text('Luis Rey'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('membership-INACTIVE')));
    await tester.pumpAndSettle();
    expect(find.text('Ana Paz'), findsOneWidget);
  });

  testWidgets('restablece la contraseña del miembro', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var resetUserId = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MinistryMembersPage(
          repository: _MembersRepository(),
          onBack: () {},
          onResetPassword: (userId) async {
            resetUserId = userId;
            return (temporaryPassword: 'Temp#99', failure: null);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ana Paz');
    await tester.pump();
    await tester.tap(find.byTooltip('Restablecer contraseña'));
    await tester.pumpAndSettle();
    expect(
      find.text('¿Generar una contraseña temporal para Ana Paz?'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Restablecer'));
    await tester.pumpAndSettle();
    expect(resetUserId, 4);
    expect(find.textContaining('Temp#99'), findsOneWidget);
    expect(find.text('Copiar contraseña'), findsOneWidget);

    await tester.tap(find.text('Copiar contraseña'));
    await tester.pump();
    expect(find.text('Contraseña copiada'), findsOneWidget);
  });
}

class _MembersRepository implements RehearsalRepository {
  MembershipStatus? listedStatus;
  (int, int, MembershipStatus)? updated;

  final _members = <MinistryMember>[
    const MinistryMember(
      ministryMemberId: 8,
      userId: 4,
      firstName: 'Ana',
      lastName: 'Paz',
      functions: ['Voz'],
      status: MembershipStatus.pending,
    ),
    const MinistryMember(
      ministryMemberId: 14,
      firstName: 'Carlos',
      lastName: 'Vega',
      functions: ['Sonido'],
      status: MembershipStatus.pending,
    ),
    const MinistryMember(
      ministryMemberId: 9,
      firstName: 'Luis',
      lastName: 'Rey',
      functions: ['Guitarra'],
      status: MembershipStatus.active,
    ),
  ];

  @override
  Future<RehearsalFailure?> create(RehearsalDraft draft) async => null;

  @override
  Future<RehearsalFailure?> update(
    int rehearsalId,
    RehearsalDraft draft,
  ) async {
    return null;
  }

  @override
  Future<RehearsalFailure?> updateMemberStatus(
    int ministryId,
    int membershipId,
    MembershipStatus status,
  ) async {
    updated = (ministryId, membershipId, status);
    final index = _members.indexWhere(
      (member) => member.ministryMemberId == membershipId,
    );
    if (index < 0) return null;
    final member = _members[index];
    _members[index] = MinistryMember(
      ministryMemberId: member.ministryMemberId,
      userId: member.userId,
      firstName: member.firstName,
      lastName: member.lastName,
      functions: member.functions,
      status: status,
    );
    return null;
  }

  @override
  Future<({List<MinistryMember>? members, RehearsalFailure? failure})>
  listMembers(
    int ministryId, {
    MembershipStatus status = MembershipStatus.active,
  }) async {
    listedStatus = status;
    return (
      members: [
        for (final member in _members)
          if (member.status == status) member,
      ],
      failure: null,
    );
  }

  @override
  Future<({List<MinistryOption>? ministries, RehearsalFailure? failure})>
  listMinistries() async {
    return (
      ministries: const [MinistryOption(id: 2, name: 'Alabanza')],
      failure: null,
    );
  }
}
