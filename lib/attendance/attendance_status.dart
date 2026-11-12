enum AttendanceStatus { present, late, absent, justified }

extension AttendanceStatusLabel on AttendanceStatus {
  String get label => switch (this) {
    AttendanceStatus.present => 'Presente',
    AttendanceStatus.late => 'Tarde',
    AttendanceStatus.absent => 'Ausente',
    AttendanceStatus.justified => 'Justificado',
  };

  String get apiValue => switch (this) {
    AttendanceStatus.present => 'ON_TIME',
    AttendanceStatus.late => 'LATE',
    AttendanceStatus.absent => 'ABSENT',
    AttendanceStatus.justified => 'JUSTIFIED',
  };

  static AttendanceStatus? fromApi(Object? raw) {
    return switch (raw) {
      'ON_TIME' => AttendanceStatus.present,
      'LATE' => AttendanceStatus.late,
      'ABSENT' => AttendanceStatus.absent,
      'JUSTIFIED' => AttendanceStatus.justified,
      _ => null,
    };
  }
}
