import 'ministry_definition.dart';
import 'service_area.dart';

class AlabanzaMinistry implements MinistryDefinition {
  const AlabanzaMinistry();

  @override
  String get id => 'alabanza';

  @override
  String get name => 'Alabanza';

  @override
  List<ServiceArea> get serviceAreas => const [
        ServiceArea(id: 'voces', name: 'Voces'),
        ServiceArea(id: 'instrumentos', name: 'Instrumentos'),
        ServiceArea(id: 'direccion', name: 'Dirección'),
      ];
}
