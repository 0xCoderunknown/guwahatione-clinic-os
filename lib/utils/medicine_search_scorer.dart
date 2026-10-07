export '../core/engines/medicine_engine.dart' show CompositionGroupResult;

import '../core/engines/medicine_engine.dart';
import '../models/medicine.dart';

/// Adapter wrapper forwarding to the unified [MedicineEngine].
class MedicineSearchScorer {
  static List<CompositionGroupResult> searchAndGroup({
    required List<Medicine> catalog,
    required String query,
    String searchMode = 'compositionFirst',
  }) {
    return MedicineEngine.searchAndGroup(
      catalog: catalog,
      query: query,
      searchMode: searchMode,
    );
  }
}
