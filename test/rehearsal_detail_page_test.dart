import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace/data/session/in_memory_token_store.dart';
import 'package:living_grace/domain/entities/rehearsal_draft.dart';
import 'package:living_grace/domain/failures/rehearsal_failure.dart';
import 'package:living_grace/domain/repositories/rehearsal_repository.dart';
import 'package:living_grace/presentation/controllers/rehearsal_form_controller.dart';
import 'package:living_grace/rehearsals/rehearsal.dart';
import 'package:living_grace/rehearsals/rehearsal_api.dart';
import 'package:living_grace/rehearsals/rehearsal_detail_page.dart';
import 'package:living_grace/rehearsals/rehearsals_page.dart';

void main() {
  test('el detalle de administrador incluye a sus miembros', () {
    final rehearsal = Rehearsal.fromJson({
      'id': 7,
      'ministry': {'id': 3, 'name': 'Alabanza'},
      'name': 'Ensayo general',
      'description': 'Voces',
      'start_at': '2026-08-12T19:00:00Z',
      'end_at': '2026-08-12T21:00:00Z',
      'tolerance_minutes': 10,
      'created_at': '2026-08-01T00:00:00Z',
      'updated_at': '2026-08-01T00:00:00Z',
      'created_by': {'id': 1, 'first_name': 'Luis', 'last_name': 'Rey'},
      'participants': [
        {
          'ministry_member_id': 10,
          'user_id': 4,
          'first_name': 'Ana',
          'last_name': 'Paz',
          'functions': ['Voz'],
          'arrival_at': null,
          'attendance_status': null,
        },
      ],
    });

    expect(rehearsal.ministryId, 3);
    expect(rehearsal.showsMembers, isTrue);
    expect(rehearsal.participants.single.fullName, 'Ana Paz');
    expect(rehearsal.participantCount, 1);
  });

  testWidgets('muestra miembros y, al confirmar, elimina el ensayo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _DetailApi();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RehearsalDetailPage(
                      api: api,
                      rehearsalId: 7,
                      canManage: true,
                      formController: RehearsalFormController(
                        repository: _QuietRepository(),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Abrir'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Ensayo general'), findsOneWidget);
    expect(find.text('Ana Paz'), findsOneWidget);
    expect(find.text('Voz'), findsOneWidget);
    expect(find.text('Miembros'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(
      find.text('¿Seguro que quieres eliminar este ensayo?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(api.deleted, isFalse);
    expect(find.text('Ensayo general'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(api.deleted, isTrue);
    expect(find.text('Abrir'), findsOneWidget);
  });

  testWidgets('guardar la edicion vuelve a cargar el ensayo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _DetailApi();
    await tester.pumpWidget(
      MaterialApp(
        home: RehearsalDetailPage(
          api: api,
          rehearsalId: 7,
          canManage: true,
          formController: RehearsalFormController(
            repository: _QuietRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Editar ensayo'), findsOneWidget);
    expect(find.text('Ensayo general'), findsWidgets);

    final submit = find.widgetWithText(FilledButton, 'Guardar cambios');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Ensayo de voces'), findsWidgets);
    expect(find.text('Ensayo actualizado.'), findsOneWidget);
    expect(api.fetches, 2);
  });

  testWidgets('al eliminar, el listado deja de mostrar ese ensayo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _ListApi();
    await tester.pumpWidget(
      MaterialApp(home: RehearsalsPage(api: api, canManage: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ensayo general'), findsOneWidget);

    await tester.tap(find.text('Ensayo general'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Ensayo general'), findsNothing);
    expect(find.text('No hay próximos ensayos.'), findsOneWidget);
    expect(api.listFetches, 2);
  });
}

Rehearsal _rehearsal(String name) {
  return Rehearsal(
    id: 7,
    name: name,
    description: 'Voces',
    ministryId: 1,
    ministryName: 'Alabanza',
    leaderName: 'Luis Rey',
    startAt: DateTime(2026, 8, 12, 19),
    endAt: DateTime(2026, 8, 12, 21),
    toleranceMinutes: 10,
    participantCount: 1,
    showsMembers: true,
    participants: const [
      RehearsalParticipant(
        ministryMemberId: 10,
        userId: 4,
        firstName: 'Ana',
        lastName: 'Paz',
        functions: ['Voz'],
      ),
    ],
  );
}

class _ListApi extends RehearsalApi {
  _ListApi() : super(tokenStore: InMemoryTokenStore()) {
    final start = DateTime.now().add(const Duration(days: 2));
    items.add(
      Rehearsal(
        id: 7,
        name: 'Ensayo general',
        description: 'Voces',
        ministryId: 1,
        ministryName: 'Alabanza',
        leaderName: 'Luis Rey',
        startAt: start,
        endAt: start.add(const Duration(hours: 2)),
        toleranceMinutes: 10,
        showsMembers: true,
        participants: const [
          RehearsalParticipant(
            ministryMemberId: 10,
            userId: 4,
            firstName: 'Ana',
            lastName: 'Paz',
            functions: ['Voz'],
          ),
        ],
      ),
    );
  }

  int listFetches = 0;
  final List<Rehearsal> items = [];

  @override
  Future<List<Rehearsal>> fetchUpcoming() async {
    listFetches++;
    return List<Rehearsal>.of(items);
  }

  @override
  Future<Rehearsal> fetchDetail(int id) async {
    return items.firstWhere((item) => item.id == id);
  }

  @override
  Future<void> delete(int id) async {
    items.removeWhere((item) => item.id == id);
  }
}

class _DetailApi extends RehearsalApi {
  _DetailApi() : super(tokenStore: InMemoryTokenStore());

  int fetches = 0;
  bool deleted = false;

  @override
  Future<Rehearsal> fetchDetail(int id) async {
    fetches++;
    return _rehearsal(fetches == 1 ? 'Ensayo general' : 'Ensayo de voces');
  }

  @override
  Future<void> delete(int id) async {
    deleted = true;
  }
}

class _QuietRepository implements RehearsalRepository {
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
