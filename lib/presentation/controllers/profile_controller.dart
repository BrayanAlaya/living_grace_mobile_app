import 'package:flutter/foundation.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/failures/profile_failure.dart';
import '../../domain/repositories/profile_repository.dart';

enum ProfileStatus { idle, loading, ready, failure }

/// Orquesta la carga del perfil. No conoce widgets ni HTTP.
class ProfileController extends ChangeNotifier {
  ProfileController({required this._repository});

  final ProfileRepository _repository;

  ProfileStatus status = ProfileStatus.idle;
  UserProfile? profile;
  ProfileFailure? failure;
  int _ticket = 0;

  void clear() {
    _ticket++;
    status = ProfileStatus.idle;
    profile = null;
    failure = null;
    notifyListeners();
  }

  Future<void> load() async {
    final ticket = ++_ticket;
    status = ProfileStatus.loading;
    failure = null;
    notifyListeners();

    final result = await _repository.getMine();
    if (ticket != _ticket) return;

    if (result.failure != null || result.profile == null) {
      status = ProfileStatus.failure;
      failure = result.failure ?? const ProfileUnexpectedFailure();
      profile = null;
      notifyListeners();
      return;
    }

    status = ProfileStatus.ready;
    profile = result.profile;
    failure = null;
    notifyListeners();
  }
}
