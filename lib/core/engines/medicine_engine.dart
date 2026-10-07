import '../../models/medicine.dart';
import '../../models/prescription_item.dart';

/// Structured grouping result for medicine catalogue search queries.
class CompositionGroupResult {
  final String compositionLabel; // e.g., 'Paracetamol 650 mg'
  final String composition; // e.g., 'Paracetamol'
  final String strength; // e.g., '650 mg'
  final String form; // e.g., 'Tablet'
  final List<Medicine> associatedBrands; // e.g., [Dolo 650, Calpol 650]
  final int score;
  final bool isCompositionMatch;

  const CompositionGroupResult({
    required this.compositionLabel,
    required this.composition,
    required this.strength,
    required this.form,
    required this.associatedBrands,
    required this.score,
    required this.isCompositionMatch,
  });
}

/// Clinical regimen defaults for routine OPD prescriptions.
class ClinicalDefaultRegimen {
  final String dosage;
  final String frequency;
  final String timing;
  final int? durationDays;
  final String? instructions;

  const ClinicalDefaultRegimen({
    required this.dosage,
    required this.frequency,
    required this.timing,
    this.durationDays,
    this.instructions,
  });
}

/// Segregated prescription items partitioned by reconciliation status.
class ReconciliationPartition {
  final List<PrescriptionItem> activeMeds;
  final List<PrescriptionItem> startedMeds;
  final List<PrescriptionItem> continuedMeds;
  final List<PrescriptionItem> stoppedMeds;

  const ReconciliationPartition({
    required this.activeMeds,
    required this.startedMeds,
    required this.continuedMeds,
    required this.stoppedMeds,
  });

  bool get hasActive => activeMeds.isNotEmpty;
  bool get hasStopped => stoppedMeds.isNotEmpty;
}

/// Pure Dart pharmacology intelligence, catalogue search scoring,
/// and medication reconciliation engine.
///
/// Zero Flutter UI dependencies.
abstract class MedicineEngine {
  /// Scores and groups catalogue medicines prioritizing chemical composition or
  /// commercial trade brands based on [searchMode] ('brandFirst', 'compositionFirst', 'both').
  static List<CompositionGroupResult> searchAndGroup({
    required List<Medicine> catalog,
    required String query,
    String searchMode = 'compositionFirst',
  }) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return _groupByComposition(catalog, defaultScore: 0);
    }

    final Map<String, List<Medicine>> groupedByComp = {};
    final Map<String, int> groupScores = {};
    final Map<String, bool> groupIsCompMatch = {};

    for (final med in catalog) {
      final compLower = med.composition.toLowerCase();
      final strengthLower = med.strength.toLowerCase();
      final fullCompLower = '${med.composition} ${med.strength}'.toLowerCase();
      final brandLower = med.productName.toLowerCase();

      int score = 0;
      bool isCompMatch = false;

      if (searchMode == 'brandFirst') {
        if (brandLower.startsWith(cleanQuery)) {
          score = 100;
        } else if (brandLower.contains(cleanQuery)) {
          score = 80;
        } else if (fullCompLower.startsWith(cleanQuery) ||
            compLower.startsWith(cleanQuery)) {
          score = 60;
          isCompMatch = true;
        } else if (fullCompLower.contains(cleanQuery) ||
            compLower.contains(cleanQuery) ||
            strengthLower.contains(cleanQuery)) {
          score = 40;
          isCompMatch = true;
        }
      } else {
        // compositionFirst or both
        if (fullCompLower.startsWith(cleanQuery) ||
            compLower.startsWith(cleanQuery)) {
          score = 100;
          isCompMatch = true;
        } else if (fullCompLower.contains(cleanQuery) ||
            compLower.contains(cleanQuery) ||
            strengthLower.contains(cleanQuery)) {
          score = 80;
          isCompMatch = true;
        } else if (brandLower.startsWith(cleanQuery)) {
          score = 60;
        } else if (brandLower.contains(cleanQuery)) {
          score = 40;
        }
      }

      if (score > 0) {
        final groupKey =
            '${med.composition.trim()}__${med.strength.trim()}__${med.form.trim()}';
        groupedByComp.putIfAbsent(groupKey, () => []).add(med);

        final currentMax = groupScores[groupKey] ?? 0;
        if (score > currentMax) {
          groupScores[groupKey] = score;
        }
        if (isCompMatch) {
          groupIsCompMatch[groupKey] = true;
        }
      }
    }

    final List<CompositionGroupResult> results = [];
    for (final entry in groupedByComp.entries) {
      final meds = entry.value;
      meds.sort((a, b) {
        final aMatch = a.productName.toLowerCase().contains(cleanQuery);
        final bMatch = b.productName.toLowerCase().contains(cleanQuery);
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
        return a.productName.compareTo(b.productName);
      });

      final first = meds.first;
      final key = entry.key;

      results.add(
        CompositionGroupResult(
          compositionLabel: first.fullCompositionLabel,
          composition: first.composition,
          strength: first.strength,
          form: first.form,
          associatedBrands: meds,
          score: groupScores[key] ?? 0,
          isCompositionMatch: groupIsCompMatch[key] ?? false,
        ),
      );
    }

    results.sort((a, b) {
      if (b.score != a.score) {
        return b.score.compareTo(a.score);
      }
      if (searchMode == 'compositionFirst') {
        if (b.isCompositionMatch != a.isCompositionMatch) {
          return b.isCompositionMatch ? 1 : -1;
        }
      } else {
        if (b.isCompositionMatch != a.isCompositionMatch) {
          return b.isCompositionMatch ? -1 : 1;
        }
      }
      return a.compositionLabel.compareTo(b.compositionLabel);
    });

    return results;
  }

  static List<CompositionGroupResult> _groupByComposition(
    List<Medicine> catalog, {
    required int defaultScore,
  }) {
    final Map<String, List<Medicine>> grouped = {};
    for (final med in catalog) {
      final key =
          '${med.composition.trim()}__${med.strength.trim()}__${med.form.trim()}';
      grouped.putIfAbsent(key, () => []).add(med);
    }

    return grouped.entries.map((e) {
      final first = e.value.first;
      return CompositionGroupResult(
        compositionLabel: first.fullCompositionLabel,
        composition: first.composition,
        strength: first.strength,
        form: first.form,
        associatedBrands: e.value,
        score: defaultScore,
        isCompositionMatch: false,
      );
    }).toList();
  }

  /// Provides clinical intelligence fallbacks for routine OPD medications.
  static ClinicalDefaultRegimen getDefaultsForMedicine(Medicine medicine) {
    if (medicine.defaultDosage != null &&
        medicine.defaultFrequency != null &&
        medicine.defaultTiming != null) {
      return ClinicalDefaultRegimen(
        dosage: medicine.defaultDosage!,
        frequency: medicine.defaultFrequency!,
        timing: medicine.defaultTiming!,
        durationDays: medicine.defaultDurationDays,
      );
    }

    final formLower = medicine.form.toLowerCase();
    final compLower = medicine.composition.toLowerCase();
    final productLower = medicine.productName.toLowerCase();
    final catLower = (medicine.category ?? '').toLowerCase();

    String dosage = '1 Tablet';
    if (formLower.contains('syrup') || formLower.contains('suspension')) {
      dosage = '5 ml';
    } else if (formLower.contains('capsule')) {
      dosage = '1 Capsule';
    } else if (formLower.contains('drop')) {
      dosage = '2 Drops';
    } else if (formLower.contains('gel') ||
        formLower.contains('cream') ||
        formLower.contains('ointment')) {
      dosage = 'Apply thin layer';
    } else if (formLower.contains('inhaler') || formLower.contains('rotacap')) {
      dosage = '1 Puff';
    } else if (formLower.contains('injection')) {
      dosage = '1 Vial';
    }

    // PPIs & Antacids: Fasting / Morning Empty Stomach
    if (compLower.contains('pantoprazole') ||
        compLower.contains('rabeprazole') ||
        compLower.contains('omeprazole') ||
        compLower.contains('esomeprazole') ||
        productLower.contains('pan ') ||
        productLower.startsWith('pan-') ||
        productLower.startsWith('rabekind') ||
        productLower.startsWith('omez')) {
      return ClinicalDefaultRegimen(
        dosage: dosage,
        frequency: '1-0-0 (OD)',
        timing: 'Before Food (Empty Stomach)',
        durationDays: 14,
        instructions: 'Take 30 minutes before morning breakfast',
      );
    }

    // Antihypertensives: Morning After Food, 30 Days
    if (compLower.contains('telmisartan') ||
        compLower.contains('amlodipine') ||
        compLower.contains('metoprolol') ||
        compLower.contains('losartan') ||
        compLower.contains('atenolol') ||
        compLower.contains('cilnidipine') ||
        productLower.contains('telma') ||
        productLower.contains('amlong') ||
        catLower.contains('antihypertensive') ||
        catLower.contains('cardio')) {
      return ClinicalDefaultRegimen(
        dosage: dosage,
        frequency: '1-0-0 (OD)',
        timing: 'After Food (Morning)',
        durationDays: 30,
        instructions: 'Take consistently at the same time every morning',
      );
    }

    // Antidiabetics: BD / OD, After Food, 30 Days
    if (compLower.contains('metformin') ||
        compLower.contains('glimepiride') ||
        compLower.contains('teneligliptin') ||
        compLower.contains('vildagliptin') ||
        compLower.contains('dapagliflozin') ||
        productLower.contains('glycomet') ||
        productLower.contains('gemer') ||
        catLower.contains('diabetic')) {
      return ClinicalDefaultRegimen(
        dosage: dosage,
        frequency: '1-0-1 (BD)',
        timing: 'After Food',
        durationDays: 30,
        instructions: 'Take immediately after principal meals',
      );
    }

    // Statins / Lipid Lowering: Night / Bedtime (HS)
    if (compLower.contains('atorvastatin') ||
        compLower.contains('rosuvastatin') ||
        productLower.contains('atorva') ||
        productLower.contains('rozavel') ||
        catLower.contains('lipid')) {
      return ClinicalDefaultRegimen(
        dosage: dosage,
        frequency: '0-0-1 (HS / Night)',
        timing: 'After Dinner',
        durationDays: 30,
        instructions: 'Take at night after dinner',
      );
    }

    // Antihistamines & Allergy: Night (HS), 5 Days
    if (compLower.contains('levocetirizine') ||
        compLower.contains('cetirizine') ||
        compLower.contains('montelukast') ||
        compLower.contains('bilastine') ||
        compLower.contains('fexofenadine') ||
        productLower.contains('montek-lc') ||
        productLower.contains('allegra')) {
      return ClinicalDefaultRegimen(
        dosage: dosage,
        frequency: '0-0-1 (HS / Night)',
        timing: 'After Dinner',
        durationDays: 5,
        instructions: 'May cause mild drowsiness',
      );
    }

    // Antibiotics: BD 5 Days
    if (compLower.contains('amoxicillin') ||
        compLower.contains('clavulanic') ||
        compLower.contains('azithromycin') ||
        compLower.contains('cefixime') ||
        compLower.contains('ciprofloxacin') ||
        compLower.contains('ofloxacin') ||
        catLower.contains('antibiotic')) {
      final isAzithro = compLower.contains('azithromycin');
      return ClinicalDefaultRegimen(
        dosage: dosage,
        frequency: isAzithro ? '1-0-0 (OD)' : '1-0-1 (BD)',
        timing: 'After Food',
        durationDays: isAzithro ? 3 : 5,
        instructions: 'Complete the entire course without skipping doses',
      );
    }

    // Analgesics & Antipyretics: SOS or 3 Days
    if (compLower.contains('paracetamol') ||
        compLower.contains('ibuprofen') ||
        compLower.contains('aceclofenac') ||
        compLower.contains('tramadol') ||
        productLower.contains('dolo') ||
        productLower.contains('calpol') ||
        catLower.contains('analgesic') ||
        catLower.contains('antipyretic')) {
      return ClinicalDefaultRegimen(
        dosage: dosage,
        frequency: 'SOS (As Needed)',
        timing: 'After Food',
        durationDays: 3,
        instructions: 'Take if fever > 100°F or body ache persists',
      );
    }

    return ClinicalDefaultRegimen(
      dosage: dosage,
      frequency: '1-0-1 (BD)',
      timing: 'After Food',
      durationDays: 5,
    );
  }

  /// Segregates a consultation's prescription list into Active vs Discontinued items.
  static ReconciliationPartition segregatePrescriptions(
      List<PrescriptionItem> items) {
    final List<PrescriptionItem> active = [];
    final List<PrescriptionItem> started = [];
    final List<PrescriptionItem> continued = [];
    final List<PrescriptionItem> stopped = [];

    for (final item in items) {
      if (item.action == MedicationAction.stop) {
        stopped.add(item);
      } else {
        active.add(item);
        if (item.action == MedicationAction.start) {
          started.add(item);
        } else if (item.action == MedicationAction.continueAction) {
          continued.add(item);
        }
      }
    }

    return ReconciliationPartition(
      activeMeds: active,
      startedMeds: started,
      continuedMeds: continued,
      stoppedMeds: stopped,
    );
  }
}
