import 'ministry_definition.dart';
import 'service_area.dart';

/// Ministerios del registro y los servicios de cada uno.
class MinistryCatalog {
  const MinistryCatalog(this.ministries);

  final List<MinistryDefinition> ministries;

  MinistryDefinition? byId(int id) {
    for (final ministry in ministries) {
      if (ministry.id == id) return ministry;
    }
    return null;
  }

  List<ServiceArea> areasFor(int? ministryId) {
    if (ministryId == null) return const [];
    return byId(ministryId)?.serviceAreas ?? const [];
  }
}
