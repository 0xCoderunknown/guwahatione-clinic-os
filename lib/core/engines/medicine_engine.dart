import '../../models/models.dart';

/// Structured grouping result for medicine catalogue search queries.
class CompositionGroupResult {
  final String compositionLabel; // e.g., 'Telmisartan 40mg'
  final String composition; // e.g., 'Telmisartan 40mg'
  final List<Medicine>
  associatedBrands; // e.g., [Telma 40 tablet, Telmikind 40 tablet]
  final int score;
  final bool isCompositionMatch;

  const CompositionGroupResult({
    required this.compositionLabel,
    required this.composition,
    required this.associatedBrands,
    required this.score,
    required this.isCompositionMatch,
  });

  /// Prominent uppercase bracketed composition header (e.g., `[TELMISARTAN 40MG]`)
  String get formattedHeader => '[${compositionLabel.toUpperCase()}]';
}

/// Clinical regimen defaults for routine OPD prescriptions.
class ClinicalDefaultRegimen {
  final String dosage;
  final String frequency;
  final String timing;
  final int? durationDays;
  final String? durationText;
  final String? instructions;

  const ClinicalDefaultRegimen({
    required this.dosage,
    required this.frequency,
    required this.timing,
    this.durationDays,
    this.durationText,
    this.instructions,
  });
}

/// Structured result from parsing clinical duration inputs (days, SOS, cont / continue).
class ParsedDuration {
  final int? durationDays;
  final String durationText; // e.g. 'To Continue', 'SOS', '5 Days'
  final bool isValid;
  final String? errorMessage;

  const ParsedDuration({
    required this.durationDays,
    required this.durationText,
    required this.isValid,
    this.errorMessage,
  });

  factory ParsedDuration.toContinue() => const ParsedDuration(
        durationDays: null,
        durationText: 'To Continue',
        isValid: true,
      );

  factory ParsedDuration.sos() => const ParsedDuration(
        durationDays: null,
        durationText: 'SOS',
        isValid: true,
      );

  factory ParsedDuration.days(int days) => ParsedDuration(
        durationDays: days,
        durationText: '$days Days',
        isValid: true,
      );

  factory ParsedDuration.invalid(String message) => ParsedDuration(
        durationDays: null,
        durationText: '',
        isValid: false,
        errorMessage: message,
      );
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
  /// and Column 2 (composition).
  ///
  /// Enforces a minimum 3-character trigger threshold (e.g. 'Tel').
  /// Returns composition cards [COMPOSITION] with associated products.
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
      final brandLower = med.productName.trim().toLowerCase();

      int score = 0;
      bool isCompMatch = false;

      // Column 2 Match: Composition / Molecule / Salt with Strength
      if (compLower == cleanQuery) {
        score = 100;
        isCompMatch = true;
      } else if (compLower.startsWith(cleanQuery)) {
        score = 90;
        isCompMatch = true;
      } else if (compLower.contains(cleanQuery)) {
        score = 70;
        isCompMatch = true;
      }

      // Column 1 Match: Product Name / Trade Brand with Form
      if (brandLower == cleanQuery) {
        if (score < 95) score = 95;
      } else if (brandLower.startsWith(cleanQuery)) {
        if (score < 80) score = 80;
      } else if (brandLower.contains(cleanQuery)) {
        if (score < 60) score = 60;
      }

      if (score > 0) {
        final groupKey = compLower;
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
          compositionLabel: first.composition,
          composition: first.composition,
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

  /// Parses clinical duration inputs flexibly:
  /// - Numbers (1 to 300 days), e.g. '5', '5d', '5 days', '21' -> durationDays: N, durationText: 'N Days'
  /// - SOS, e.g. 'sos', 'SoS', 'SOS', 's.o.s', 'as needed' -> durationDays: null, durationText: 'SOS'
  /// - Continue, e.g. 'cont', 'continue', 'to continue', 'chronic', 'ongoing' or empty -> durationDays: null, durationText: 'To Continue'
  /// - Rejects <= 0 days, > 300 days, or unparseable malformed text.
  static ParsedDuration parseDuration(String? input) {
    if (input == null || input.trim().isEmpty) {
      return ParsedDuration.toContinue();
    }
    final clean = input.trim().toLowerCase();

    // 1. SOS (As Needed) matching
    if (clean == 'sos' ||
        clean == 's.o.s' ||
        clean == 's.o.s.' ||
        clean == 'as needed' ||
        clean.startsWith('sos ') ||
        clean.startsWith('sos(')) {
      return ParsedDuration.sos();
    }

    // 2. Chronic / Ongoing / To Continue matching
    if (clean == 'cont' ||
        clean == 'continue' ||
        clean == 'to continue' ||
        clean == 'chronic' ||
        clean == 'ongoing' ||
        clean.startsWith('cont ') ||
        clean.startsWith('to continue')) {
      return ParsedDuration.toContinue();
    }

    // 3. Acute course in days (1-300 days)
    final numericMatch = RegExp(r'^-?\d+').firstMatch(clean);
    if (numericMatch != null) {
      final val = int.tryParse(numericMatch.group(0)!);
      if (val != null) {
        if (val <= 0) {
          return ParsedDuration.invalid(
            'Duration days must be greater than 0 (1 to 300 days).',
          );
        }
        if (val > 300) {
          return ParsedDuration.invalid('Duration cannot exceed 300 days.');
        }
        return ParsedDuration.days(val);
      }
    }

    return ParsedDuration.invalid(
      "Enter days (1-300), 'cont' (continue), or 'SOS'.",
    );
  }

  /// Provides clinical intelligence fallbacks for routine OPD medications.
  static ClinicalDefaultRegimen getDefaultsForMedicine(Medicine medicine) {
    if (medicine.defaultDosage != null &&
        medicine.defaultFrequency != null &&
        medicine.defaultTiming != null) {
      final parsed = parseDuration(medicine.defaultDuration ??
          (medicine.defaultDurationDays != null
              ? '${medicine.defaultDurationDays} days'
              : 'To continue'));
      return ClinicalDefaultRegimen(
        dosage: medicine.defaultDosage!,
        frequency: medicine.defaultFrequency!,
        timing: medicine.defaultTiming!,
        durationDays: parsed.durationDays,
        durationText: parsed.durationText,
      );
    }

    final compLower = medicine.composition.toLowerCase();
    final productLower = medicine.productName.toLowerCase();

    String dosage = '1 Tablet';
    if (productLower.contains('syrup') || productLower.contains('suspension')) {
      dosage = '5 ml';
    } else if (productLower.contains('capsule')) {
      dosage = '1 Capsule';
    } else if (productLower.contains('drop')) {
      dosage = '2 Drops';
    } else if (productLower.contains('gel') ||
        productLower.contains('cream') ||
        productLower.contains('ointment')) {
      dosage = 'Apply thin layer';
    } else if (productLower.contains('inhaler') ||
        productLower.contains('rotacap')) {
      dosage = '1 Puff';
    } else if (productLower.contains('injection')) {
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
        productLower.contains('amlong')) {
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
        productLower.contains('gemer')) {
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
        productLower.contains('rozavel')) {
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
        compLower.contains('ofloxacin')) {
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
        productLower.contains('calpol')) {
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
          (m.manufacturer != null &&
              m.manufacturer!.toLowerCase().contains(cleanQuery));

      final matchesForm =
          formFilter == 'All' ||
          m.productName.toLowerCase().contains(formFilter.toLowerCase());

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
    return const [];
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
