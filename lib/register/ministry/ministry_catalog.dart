import 'ministry_definition.dart';
import 'service_area.dart';

/// O — Closed for modification: el formulario solo pregunta al catálogo.
/// Para agregar un ministerio se añade una MinistryDefinition, no se toca la UI.
class MinistryCatalog {
  const MinistryCatalog(this.ministries);

  final List<MinistryDefinition> ministries;

  MinistryDefinition? byId(String id) {
    for (final ministry in ministries) {
      if (ministry.id == id) return ministry;
    }
    return null;
  }

  List<ServiceArea> areasFor(String? ministryId) {
    if (ministryId == null) return const [];
    return byId(ministryId)?.serviceAreas ?? const [];
  }
}
