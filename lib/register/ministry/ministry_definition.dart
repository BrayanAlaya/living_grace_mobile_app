import 'service_area.dart';

/// O — Open/Closed: el registro se extiende con ministerios nuevos
/// creando otra clase, sin modificar el formulario ni el catálogo.
abstract class MinistryDefinition {
  String get id;
  String get name;
  List<ServiceArea> get serviceAreas;
}
