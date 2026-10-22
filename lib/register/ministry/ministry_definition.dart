import 'service_area.dart';

/// Ministerio disponible al registrarse, con sus servicios.
class MinistryDefinition {
  const MinistryDefinition({
    required this.id,
    required this.name,
    this.serviceAreas = const [],
  });

  final int id;
  final String name;
  final List<ServiceArea> serviceAreas;

  factory MinistryDefinition.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! int || name is! String || name.trim().isEmpty) {
      throw const FormatException('MinistryRegistrationInfo');
    }

    return MinistryDefinition(
      id: id,
      name: name.trim(),
      serviceAreas: _services(json['function_options']),
    );
  }
}

List<ServiceArea> _services(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map) ?_service(Map<String, dynamic>.from(item)),
  ];
}

ServiceArea? _service(Map<String, dynamic> json) {
  final id = json['id'];
  final name = json['name'];
  if (id is! int || name is! String || name.trim().isEmpty) return null;
  return ServiceArea(id: id, name: name.trim());
}
