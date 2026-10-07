import '../models/medicine.dart';

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

/// Provides clinical intelligence fallbacks for routine OPD medications.
///
/// If a [Medicine] has explicit defaults stored in Firestore, those take precedence.
/// Otherwise, this helper applies pharmacological rules based on dosage form,
/// molecule class, and clinical treatment standards in Indian OPD practices.
class ClinicalDefaultsHelper {
  static ClinicalDefaultRegimen getDefaultsForMedicine(Medicine medicine) {
    // 1. Explicit medicine-level overrides from catalogue take highest priority
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

    // Default dosage by form
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

    // 2. PPIs & Antacids: Fasting / Morning Empty Stomach
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

    // 3. Antihypertensives: Morning After Food, 30 Days (Continuous)
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

    // 4. Antidiabetics: BD / OD, After Food, 30 Days (Continuous)
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

    // 5. Statins / Lipid Lowering: Night / Bedtime (HS)
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

    // 6. Antihistamines & Allergy: Night (HS), 5 Days
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

    // 7. Antibiotics: BD 5 Days
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

    // 8. Analgesics & Antipyretics: SOS or 3 Days
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

    // 9. Standard safe OPD fallback
    return ClinicalDefaultRegimen(
      dosage: dosage,
      frequency: '1-0-1 (BD)',
      timing: 'After Food',
      durationDays: 5,
    );
  }
}
