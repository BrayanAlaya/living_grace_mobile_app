import 'package:flutter/foundation.dart';

import '../../domain/entities/rehearsal_draft.dart';
import '../../domain/failures/rehearsal_failure.dart';
import '../../domain/repositories/rehearsal_repository.dart';

/// Carga ministerios y miembros, y envía el ensayo.
class RehearsalFormController extends ChangeNotifier {
  RehearsalFormController({required this._repository});

  final RehearsalRepository _repository;

  List<MinistryOption> ministries = const [];
  List<MinistryMember> members = const [];
  bool loadingMinistries = false;
  bool loadingMembers = false;
  bool submitting = false;
  RehearsalFailure? failure;
  int? ministryId;
  int _ticket = 0;

  Future<void> load() async {
    final ticket = ++_ticket;
    loadingMinistries = true;
    loadingMembers = false;
    submitting = false;
    failure = null;
    ministries = const [];
    members = const [];
    ministryId = null;
    notifyListeners();

    final result = await _repository.listMinistries();
    if (ticket != _ticket) return;

    loadingMinistries = false;
    failure = result.failure;
    ministries = result.ministries ?? const [];
    notifyListeners();
  }

  Future<void> selectMinistry(int id) async {
    ministryId = id;
    members = const [];
    loadingMembers = true;
    failure = null;
    notifyListeners();

    final result = await _repository.listMembers(id);
    if (ministryId != id) return;

    loadingMembers = false;
    failure = result.failure;
    members = result.members ?? const [];
    notifyListeners();
  }

  Future<bool> submit(RehearsalDraft draft) async {
    submitting = true;
    failure = null;
    notifyListeners();

    final error = await _repository.create(draft);
    submitting = false;
    failure = error;
    notifyListeners();
    return error == null;
  }
}
