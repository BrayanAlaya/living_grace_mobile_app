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
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Filtrar por ministerio'), findsOneWidget);
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

    await _chooseMinistry(tester, 'Alabanza');

    expect(find.text('Miembros'), findsOneWidget);
    expect(find.text('Ana Paz'), findsOneWidget);
    expect(repository.requestedMinistryId, 1);

    await tester.tap(find.text('Ana Paz'));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  testWidgets('cambiar de ministerio conserva los miembros seleccionados', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = RehearsalFormController(
      repository: _MultiMinistryRepository(),
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

    await _chooseMinistry(tester, 'Alabanza');
    await tester.tap(find.text('Ana Paz'));
    await tester.pump();

    await _chooseMinistry(tester, 'Producción');

    expect(find.text('Ana Paz'), findsOneWidget);
    expect(find.text('Luis Rey'), findsOneWidget);
    expect(find.textContaining('Alabanza'), findsWidgets);

    final ana = _checkboxFor(tester, 'Ana Paz');
    final luis = _checkboxFor(tester, 'Luis Rey');
    expect(ana.value, isTrue);
    expect(luis.value, isFalse);

    await tester.tap(find.text('Luis Rey'));
    await tester.pump();

    expect(_checkboxFor(tester, 'Ana Paz').value, isTrue);
    expect(_checkboxFor(tester, 'Luis Rey').value, isTrue);
  });

  testWidgets('editar rellena el formulario y confirma con los cambios', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _UpdatingRepository();
    final controller = RehearsalFormController(repository: repository);
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: CreateRehearsalPage(
          controller: controller,
          seed: RehearsalFormSeed(
            rehearsalId: 7,
            ministryId: 1,
            ministryName: 'Alabanza',
            name: 'Ensayo general',
            description: 'Voces',
            startAt: DateTime(2026, 8, 12, 19),
            endAt: DateTime(2026, 8, 12, 21),
            toleranceMinutes: 10,
            members: const [
              MinistryMember(
                ministryMemberId: 10,
                firstName: 'Ana',
                lastName: 'Paz',
                functions: ['Voz'],
              ),
            ],
          ),
          onBack: () {},
          onCreated: () => saved = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar ensayo'), findsOneWidget);
    expect(find.text('Ensayo general'), findsOneWidget);
    expect(find.text('Voces'), findsOneWidget);
    expect(find.text('12/08/2026 19:00'), findsOneWidget);
    expect(_checkboxFor(tester, 'Ana Paz').value, isTrue);

    await tester.enterText(find.text('Ensayo general'), 'Ensayo de voces');
    final submit = find.widgetWithText(FilledButton, 'Guardar cambios');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(repository.updatedId, 7);
    expect(repository.updated?.name, 'Ensayo de voces');
    expect(repository.updated?.ministryMemberIds, [10]);
    expect(repository.updated?.toleranceMinutes, 10);
  });
}

Future<void> _chooseMinistry(WidgetTester tester, String name) async {
  final opener = find.byIcon(Icons.keyboard_arrow_down_rounded);
  await tester.ensureVisible(opener);
  await tester.tap(opener);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Checkbox _checkboxFor(WidgetTester tester, String name) {
  final row = find.ancestor(
    of: find.text(name),
    matching: find.byType(InkWell),
  );
  return tester.widget<Checkbox>(
    find.descendant(of: row, matching: find.byType(Checkbox)),
  );
}

class _UpdatingRepository extends _ReadyRehearsalRepository {
  int? updatedId;
  RehearsalDraft? updated;

  @override
  Future<RehearsalFailure?> update(
    int rehearsalId,
    RehearsalDraft draft,
  ) async {
    updatedId = rehearsalId;
    updated = draft;
    return null;
  }
}

class _ReadyRehearsalRepository implements RehearsalRepository {
  int? requestedMinistryId;

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

class _MultiMinistryRepository implements RehearsalRepository {
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
  Future<({List<MinistryMember>? members, RehearsalFailure? failure})>
  listMembers(int ministryId) async {
    if (ministryId == 2) {
      return (
        members: const [
          MinistryMember(
            ministryMemberId: 20,
            firstName: 'Luis',
            lastName: 'Rey',
            functions: ['Guitarra'],
          ),
        ],
        failure: null,
      );
    }
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
      ministries: const [
        MinistryOption(id: 1, name: 'Alabanza'),
        MinistryOption(id: 2, name: 'Producción'),
      ],
      failure: null,
    );
  }
}
