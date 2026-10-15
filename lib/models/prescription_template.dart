import 'prescription_item.dart';

/// Single medication entry within a prescription template preset.
class PrescriptionTemplateItem {
  final String medicineName;
  final String composition;
  final String? strength;
  final String? form;
  final String? manufacturer;
  final String dosage;
  final String frequency;
  final String timing;
  final int? durationDays;
  final String? instructions;

  const PrescriptionTemplateItem({
    required this.medicineName,
    required this.composition,
    this.strength,
    this.form,
    this.manufacturer,
    this.dosage = '1 Tablet',
    this.frequency = '1-0-1 (BD)',
    this.timing = 'After Food',
    this.durationDays = 5,
    this.instructions,
  });

  /// Converts this template item into a live [PrescriptionItem] staged for consultation.
  PrescriptionItem toPrescriptionItem({
    required String id,
    MedicationAction action = MedicationAction.start,
  }) {
    return PrescriptionItem(
      id: id,
      action: action,
      medicineName: medicineName,
      composition: composition,
      strength: strength,
      form: form,
      manufacturer: manufacturer,
      dosage: dosage,
      frequency: frequency,
      timing: timing,
      durationDays: durationDays,
      instructions: instructions,
    );
  }
}

/// Pre-configured clinical prescription template for high-volume OPD presentations.
class PrescriptionTemplate {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final List<PrescriptionTemplateItem> items;

  const PrescriptionTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.emoji = '⚡',
    required this.items,
  });
}

/// Forensic result returned when applying a template to an encounter form.
class TemplateApplicationResult {
  final String templateName;
  final List<PrescriptionItem> addedItems;
  final List<PrescriptionTemplateItem> skippedDuplicates;

  const TemplateApplicationResult({
    required this.templateName,
    required this.addedItems,
    required this.skippedDuplicates,
  });

  bool get hasSkipped => skippedDuplicates.isNotEmpty;

  bool get hasAdded => addedItems.isNotEmpty;
}
