import 'ministry_definition.dart';
import 'service_area.dart';

class ProduccionMinistry implements MinistryDefinition {
  const ProduccionMinistry();

  @override
  String get id => 'produccion';

  @override
  String get name => 'Producción';

  @override
  List<ServiceArea> get serviceAreas => const [
        ServiceArea(id: 'audio', name: 'Audio'),
        ServiceArea(id: 'video', name: 'Video'),
        ServiceArea(id: 'iluminacion', name: 'Iluminación'),
      ];
}
