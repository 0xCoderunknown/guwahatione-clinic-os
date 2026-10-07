export '../core/engines/medicine_engine.dart' show ClinicalDefaultRegimen;

import '../core/engines/medicine_engine.dart';
import '../models/medicine.dart';

/// Adapter wrapper forwarding to the unified [MedicineEngine].
class ClinicalDefaultsHelper {
  static ClinicalDefaultRegimen getDefaultsForMedicine(Medicine medicine) {
    return MedicineEngine.getDefaultsForMedicine(medicine);
  }
}
