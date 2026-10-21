import '../../domain/failures/rehearsal_failure.dart';

class RehearsalFormInput {
  const RehearsalFormInput({
    required this.ministryId,
    required this.name,
    required this.startAt,
    required this.endAt,
    required this.toleranceText,
    required this.memberIds,
  });

  final int? ministryId;
  final String name;
  final DateTime? startAt;
  final DateTime? endAt;
  final String toleranceText;
  final List<int> memberIds;
}

/// Reglas locales de POST /rehearsals, antes de llamar a la API.
class RehearsalFormValidator {
  const RehearsalFormValidator();

  RehearsalFailure? validate(RehearsalFormInput input) {
    if (input.ministryId == null) {
      return const RehearsalValidationFailure('Selecciona un ministerio.');
    }
    if (input.name.trim().isEmpty) {
      return const RehearsalValidationFailure('Escribe el nombre del ensayo.');
    }
    if (input.startAt == null) {
      return const RehearsalValidationFailure(
        'Elige la fecha y hora de inicio.',
      );
    }
    if (input.endAt == null) {
      return const RehearsalValidationFailure('Elige la fecha y hora de fin.');
    }
    if (!input.endAt!.isAfter(input.startAt!)) {
      return const RehearsalValidationFailure(
        'La hora de fin debe ser posterior al inicio.',
      );
    }

    final tolerance = input.toleranceText.trim();
    if (tolerance.isNotEmpty) {
      final minutes = int.tryParse(tolerance);
      if (minutes == null || minutes < 0) {
        return const RehearsalValidationFailure(
          'La tolerancia debe ser un número mayor o igual a 0.',
        );
      }
    }

    if (input.memberIds.isEmpty) {
      return const RehearsalValidationFailure(
        'Selecciona al menos un miembro.',
      );
    }
    return null;
  }

  int toleranceMinutes(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }
}
