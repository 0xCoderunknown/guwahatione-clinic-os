import '../../models/models.dart';

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

  /// Prominent uppercase bracketed composition header (e.g., `[TELMISARTAN 40mg]`)
  String get formattedHeader => '[${compositionLabel.toUpperCase()}]';
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
  /// Searches catalogue medicines referring strictly to Column 1 (productName)
  /// and Column 2 (composition + strength).
  ///
  /// Enforces a minimum 3-character trigger threshold (e.g. 'Tel').
  /// Returns composition cards [COMPOSITION STRENGTH] with associated products.
  static List<CompositionGroupResult> searchAndGroup({
    required List<Medicine> catalog,
    required String query,
    int minQueryLength = 3,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final isAlphanumericShort =
        cleanQuery.length >= 2 && RegExp(r'\d').hasMatch(cleanQuery);
    if (cleanQuery.length < minQueryLength && !isAlphanumericShort) {
      return const [];
    }

    final Map<String, List<Medicine>> groupedByComp = {};
    final Map<String, int> groupScores = {};
    final Map<String, bool> groupIsCompMatch = {};

    for (final med in catalog) {
      final compLower = med.composition.trim().toLowerCase();
      final strengthLower = med.strength.trim().toLowerCase();
      final fullCompLower =
          '${med.composition} ${med.strength}'.trim().toLowerCase();
      final brandLower = med.productName.trim().toLowerCase();

      int score = 0;
      bool isCompMatch = false;

      // Column 2 Match: Composition / Molecule / Salt
      if (compLower == cleanQuery || fullCompLower == cleanQuery) {
        score = 100;
        isCompMatch = true;
      } else if (compLower.startsWith(cleanQuery) ||
          fullCompLower.startsWith(cleanQuery)) {
        score = 90;
        isCompMatch = true;
      } else if (compLower.contains(cleanQuery) ||
          fullCompLower.contains(cleanQuery) ||
          strengthLower.contains(cleanQuery)) {
        score = 70;
        isCompMatch = true;
      }

      // Column 1 Match: Product Name / Trade Brand
      if (brandLower == cleanQuery) {
        if (score < 100) score = 100;
      } else if (brandLower.startsWith(cleanQuery)) {
        if (score < 90) score = 90;
      } else if (brandLower.contains(cleanQuery)) {
        if (score < 70) score = 70;
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
      // Sort matching brands to the front
      meds.sort((a, b) {
        final aLower = a.productName.toLowerCase();
        final bLower = b.productName.toLowerCase();
        final aExact = aLower == cleanQuery;
        final bExact = bLower == cleanQuery;
        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;

        final aStarts = aLower.startsWith(cleanQuery);
        final bStarts = bLower.startsWith(cleanQuery);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;

        final aContains = aLower.contains(cleanQuery);
        final bContains = bLower.contains(cleanQuery);
        if (aContains && !bContains) return -1;
        if (!aContains && bContains) return 1;

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
      return a.compositionLabel.compareTo(b.compositionLabel);
    });

    return results;
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
    List<PrescriptionItem> items,
  ) {
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

  /// Filters and sorts catalogue medicines by search query and dosage form.
  static List<Medicine> filterAndSortCatalogue({
    required List<Medicine> catalog,
    required String query,
    String formFilter = 'All',
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final filtered = catalog.where((m) {
      final matchesQuery =
          cleanQuery.isEmpty ||
          m.productName.toLowerCase().contains(cleanQuery) ||
          m.composition.toLowerCase().contains(cleanQuery) ||
          m.strength.toLowerCase().contains(cleanQuery);

      final matchesForm =
          formFilter == 'All' ||
          m.form.toLowerCase() == formFilter.toLowerCase();

      return matchesQuery && matchesForm;
    }).toList();

    filtered.sort((a, b) {
      final compCmp = a.composition.compareTo(b.composition);
      if (compCmp != 0) return compCmp;
      return a.productName.compareTo(b.productName);
    });

    return filtered;
  }

  /// Counts the total number of distinct chemical compositions/molecules in the catalogue.
  static int countUniqueMolecules(List<Medicine> catalog) {
    return catalog
        .map((m) => m.composition.trim().toLowerCase())
        .where((c) => c.isNotEmpty)
        .toSet()
        .length;
  }

  /// Canonical preset prescription templates for common OPD clinical conditions.
  static List<PrescriptionTemplate> getDefaultPrescriptionTemplates() {
    return const [
      PrescriptionTemplate(
        id: 'tmpl_uri_flu',
        name: 'URI / Pharyngitis',
        description: 'Dolo 650 + Azithral 500 + Levocet 5 + Pan 40',
        emoji: '🤧',
        items: [
          PrescriptionTemplateItem(
            medicineName: 'Dolo 650',
            composition: 'Paracetamol 650mg',
            dosage: '1 Tablet',
            frequency: '1-0-1 (BD)',
            timing: 'After Food',
            durationDays: 5,
            instructions: 'SOS for fever or throat pain',
          ),
          PrescriptionTemplateItem(
            medicineName: 'Azithral 500',
            composition: 'Azithromycin 500mg',
            dosage: '1 Tablet',
            frequency: '1-0-0 (OD)',
            timing: 'After Food',
            durationDays: 3,
            instructions: 'Take at fixed time daily',
          ),
          PrescriptionTemplateItem(
            medicineName: 'Levocet 5',
            composition: 'Levocetirizine 5mg',
            dosage: '1 Tablet',
            frequency: '0-0-1 (HS)',
            timing: 'After Food',
            durationDays: 5,
            instructions: 'Night at bedtime for runny nose / sneezing',
          ),
          PrescriptionTemplateItem(
            medicineName: 'Pan 40',
            composition: 'Pantoprazole 40mg',
            dosage: '1 Tablet',
            frequency: '1-0-0 (OD)',
            timing: 'Before Food',
            durationDays: 5,
            instructions: 'Empty stomach in morning',
          ),
        ],
      ),
      PrescriptionTemplate(
        id: 'tmpl_acute_gastritis',
        name: 'Acute Gastritis',
        description: 'Pan 40 + Domstal 10 + Sucrafil O Suspension',
        emoji: '🔥',
        items: [
          PrescriptionTemplateItem(
            medicineName: 'Pan 40',
            composition: 'Pantoprazole 40mg',
            dosage: '1 Tablet',
            frequency: '1-0-0 (OD)',
            timing: 'Before Food',
            durationDays: 14,
            instructions: 'Empty stomach 30 mins before breakfast',
          ),
          PrescriptionTemplateItem(
            medicineName: 'Domstal 10',
            composition: 'Domperidone 10mg',
            dosage: '1 Tablet',
            frequency: '1-0-1 (BD)',
            timing: 'Before Food',
            durationDays: 5,
            instructions: 'Before meals for nausea / bloating',
          ),
          PrescriptionTemplateItem(
            medicineName: 'Sucrafil O',
            composition: 'Sucralfate 1000mg + Oxetacaine 20mg',
            dosage: '10 ml',
            frequency: '1-1-1 (TDS)',
            timing: 'Before Food',
            durationDays: 7,
            instructions: 'Shake well, 30 min before meals',
          ),
        ],
      ),
      PrescriptionTemplate(
        id: 'tmpl_gastroenteritis',
        name: 'Gastroenteritis / Diarrhea',
        description: 'O2 (Oflox-Ornidazole) + ORS + Darolac + Dolo 650 SOS',
        emoji: '💧',
        items: [
          PrescriptionTemplateItem(
            medicineName: 'O2 Tablet',
            composition: 'Ofloxacin 200mg + Ornidazole 500mg',
            dosage: '1 Tablet',
            frequency: '1-0-1 (BD)',
            timing: 'After Food',
            durationDays: 5,
            instructions: 'Complete full 5-day course',
          ),
          PrescriptionTemplateItem(
            medicineName: 'ORS Sachet',
            composition: 'Oral Rehydration Salts IP',
            dosage: '1 Sachet',
            frequency: 'SOS (As Needed)',
            timing: 'After Food',
            durationDays: 3,
            instructions:
                'Dissolve 1 packet in 1 litre drinking water, sip frequently',
          ),
          PrescriptionTemplateItem(
            medicineName: 'Darolac Capsule',
            composition: 'Lactobacillus & Probiotic Blend',
            dosage: '1 Capsule',
            frequency: '1-0-1 (BD)',
            timing: 'After Food',
            durationDays: 5,
            instructions: 'With or after meals',
          ),
          PrescriptionTemplateItem(
            medicineName: 'Dolo 650',
            composition: 'Paracetamol 650mg',
            dosage: '1 Tablet',
            frequency: 'SOS (As Needed)',
            timing: 'After Food',
            durationDays: 3,
            instructions: 'Only if fever or abdominal cramps occur',
          ),
        ],
      ),
      PrescriptionTemplate(
        id: 'tmpl_fever_viral',
        name: 'Viral Fever / SOS',
        description: 'Dolo 650 + Pan 40 + Limcee Chewable',
        emoji: '🌡️',
        items: [
          PrescriptionTemplateItem(
            medicineName: 'Dolo 650',
            composition: 'Paracetamol 650mg',
            dosage: '1 Tablet',
            frequency: '1-1-1 (TDS)',
            timing: 'After Food',
            durationDays: 5,
            instructions: 'SOS for fever > 100°F or body ache; min 6 hrs gap',
          ),
          PrescriptionTemplateItem(
            medicineName: 'Pan 40',
            composition: 'Pantoprazole 40mg',
            dosage: '1 Tablet',
            frequency: '1-0-0 (OD)',
            timing: 'Before Food',
            durationDays: 5,
            instructions: 'Morning before food',
          ),
          PrescriptionTemplateItem(
            medicineName: 'Limcee 500',
            composition: 'Vitamin C 500mg',
            dosage: '1 Tablet',
            frequency: '1-0-0 (OD)',
            timing: 'After Food',
            durationDays: 10,
            instructions: 'Chewable tablet after food',
          ),
        ],
      ),
      PrescriptionTemplate(
        id: 'tmpl_chronic_htn_starter',
        name: 'HTN Chronic Starter',
        description: 'Telma 40 (Telmisartan 40mg) chronic baseline',
        emoji: '❤️',
        items: [
          PrescriptionTemplateItem(
            medicineName: 'Telma 40',
            composition: 'Telmisartan 40mg',
            dosage: '1 Tablet',
            frequency: '1-0-0 (OD)',
            timing: 'After Food',
            durationDays: null,
            instructions: 'Morning after breakfast daily; monitor BP',
          ),
        ],
      ),
    ];
  }

  /// Evaluates and applies a [PrescriptionTemplate] against existing active prescription items,
  /// skipping duplicate medications (by name or normalized composition).
  static TemplateApplicationResult evaluateTemplateApplication({
    required PrescriptionTemplate template,
    required List<PrescriptionItem> existingItems,
    required String Function() uuidGenerator,
  }) {
    final List<PrescriptionItem> toAdd = [];
    final List<PrescriptionTemplateItem> skipped = [];

    // Build normalized lookup keys of active existing items
    final existingKeys = <String>{};
    for (final item in existingItems) {
      if (item.action != MedicationAction.stop) {
        existingKeys.add(_normalizeMedKey(item.medicineName));
        existingKeys.add(_normalizeMedKey(item.composition));
      }
    }

    for (final tmplItem in template.items) {
      final nameKey = _normalizeMedKey(tmplItem.medicineName);
      final compKey = _normalizeMedKey(tmplItem.composition);

      if (existingKeys.contains(nameKey) || existingKeys.contains(compKey)) {
        skipped.add(tmplItem);
      } else {
        toAdd.add(tmplItem.toPrescriptionItem(id: uuidGenerator()));
        existingKeys.add(nameKey);
        existingKeys.add(compKey);
      }
    }

    return TemplateApplicationResult(
      templateName: template.name,
      addedItems: toAdd,
      skippedDuplicates: skipped,
    );
  }

  static String _normalizeMedKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
