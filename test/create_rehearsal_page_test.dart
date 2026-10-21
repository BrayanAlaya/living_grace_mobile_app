import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/domain/entities/rehearsal_draft.dart';
import 'package:living_grace/domain/failures/rehearsal_failure.dart';
import 'package:living_grace/domain/repositories/rehearsal_repository.dart';
import 'package:living_grace/presentation/controllers/rehearsal_form_controller.dart';
import 'package:living_grace/presentation/pages/create_rehearsal_page.dart';
import 'package:living_grace/presentation/rehearsal/rehearsal_form_validator.dart';

void main() {
  test('exige ministerio, nombre, fechas y un miembro', () {
    const validator = RehearsalFormValidator();
    final start = DateTime(2026, 8, 12, 19);
    final end = DateTime(2026, 8, 12, 18);

    expect(
      validator
          .validate(
            const RehearsalFormInput(
              ministryId: null,
              name: 'General',
              startAt: null,
              endAt: null,
              toleranceText: '',
              memberIds: [],
            ),
          )
          ?.message,
      'Selecciona un ministerio.',
    );

    expect(
      validator
          .validate(
            RehearsalFormInput(
              ministryId: 1,
              name: 'General',
              startAt: start,
              endAt: end,
              toleranceText: '',
              memberIds: const [4],
            ),
          )
          ?.message,
      'La hora de fin debe ser posterior al inicio.',
    );

    expect(validator.toleranceMinutes(''), 0);
    expect(validator.toleranceMinutes('15'), 15);
  });

  testWidgets('programar ensayo pide el ministerio antes de enviar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = RehearsalFormController(
      repository: _ReadyRehearsalRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CreateRehearsalPage(
          controller: controller,
          onBack: () {},
          onCreated: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Programar Ensayo'), findsOneWidget);
    expect(find.text('Ministerio'), findsOneWidget);
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Miembros'), findsOneWidget);

    final submit = find.widgetWithText(FilledButton, 'Programar ensayo');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Selecciona un ministerio.'), findsOneWidget);
  });

  testWidgets('el ministerio lista sus miembros y se envían al crear', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _ReadyRehearsalRepository();
    final controller = RehearsalFormController(repository: repository);

    await tester.pumpWidget(
      MaterialApp(
        home: CreateRehearsalPage(
          controller: controller,
          onBack: () {},
          onCreated: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elige un ministerio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alabanza'));
    await tester.pumpAndSettle();

    expect(find.text('Miembros de Alabanza'), findsOneWidget);
    expect(find.text('Ana Paz'), findsOneWidget);
    expect(repository.requestedMinistryId, 1);

    await tester.tap(find.text('Ana Paz'));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}

class _ReadyRehearsalRepository implements RehearsalRepository {
  int? requestedMinistryId;

  @override
  Future<RehearsalFailure?> create(RehearsalDraft draft) async => null;

  @override
  Future<({List<MinistryMember>? members, RehearsalFailure? failure})>
  listMembers(int ministryId) async {
    requestedMinistryId = ministryId;
    return (
      members: const [
        MinistryMember(
          ministryMemberId: 10,
          firstName: 'Ana',
          lastName: 'Paz',
          functions: ['Voz'],
        ),
      ],
      failure: null,
    );
  }

  @override
  Future<({List<MinistryOption>? ministries, RehearsalFailure? failure})>
  listMinistries() async {
    return (
      ministries: const [MinistryOption(id: 1, name: 'Alabanza')],
      failure: null,
    );
  }
}
