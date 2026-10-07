enum MedicationAction {
  start,
  continueAction,
  stop;

  String get code {
    switch (this) {
      case MedicationAction.start:
        return 'START';
      case MedicationAction.continueAction:
        return 'CONTINUE';
      case MedicationAction.stop:
        return 'STOP';
    }
  }

  String get displayName => code;

  static MedicationAction fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'CONTINUE':
        return MedicationAction.continueAction;
      case 'STOP':
        return MedicationAction.stop;
      case 'START':
      default:
        return MedicationAction.start;
    }
  }
}

class PrescriptionItem {
  final String id;
  final MedicationAction action;
  final String? medicineId; // Catalog reference if selected from master
  final String medicineName; // Trade name (e.g., 'Dolo 650' or entered name)
  final String composition; // Generic chemical + strength (e.g., 'Paracetamol 650mg')
  final String dosage; // e.g., '1 Tablet', '5 ml'
  final String frequency; // e.g., '1-0-1', 'OD (Once Daily)', 'BD'
  final String timing; // e.g., 'After Food', 'Before Food'
  final int? durationDays; // Nullable: null for chronic drugs; integer for acute courses
  final String? stopReason; // Optional reason when action == STOP
  final String? unlistedName; // Fallback field for outside medications not in catalog
  final String? instructions; // e.g., 'Take with warm water'

  const PrescriptionItem({
    required this.id,
    required this.action,
    this.medicineId,
    required this.medicineName,
    required this.composition,
    this.dosage = '1 Tablet',
    this.frequency = '1-0-1',
    this.timing = 'After Food',
    this.durationDays,
    this.stopReason,
    this.unlistedName,
    this.instructions,
  });

  /// Returns true if this medication is an ongoing chronic therapy (indefinite duration)
  bool get isChronic => durationDays == null;

  /// Returns true if this medication is currently active on today's prescription schedule
  bool get isActive => action != MedicationAction.stop;

  /// Name to display on prescription (prefers unlistedName if set, otherwise medicineName)
  String get effectiveName {
    if (unlistedName != null && unlistedName!.trim().isNotEmpty) {
      return unlistedName!.trim();
    }
    return medicineName;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action.code,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'composition': composition,
      'dosage': dosage,
      'frequency': frequency,
      'timing': timing,
      'durationDays': durationDays,
      'stopReason': stopReason,
      'unlistedName': unlistedName,
      'instructions': instructions,
    };
  }

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      id: json['id'] as String? ?? '',
      action: MedicationAction.fromCode(json['action'] as String?),
      medicineId: json['medicineId'] as String?,
      medicineName: json['medicineName'] as String? ?? '',
      composition: json['composition'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '1 Tablet',
      frequency: json['frequency'] as String? ?? '1-0-1',
      timing: json['timing'] as String? ?? 'After Food',
      durationDays: (json['durationDays'] as num?)?.toInt(),
      stopReason: json['stopReason'] as String?,
      unlistedName: json['unlistedName'] as String?,
      instructions: json['instructions'] as String?,
    );
  }

  PrescriptionItem copyWith({
    String? id,
    MedicationAction? action,
    String? medicineId,
    String? medicineName,
    String? composition,
    String? dosage,
    String? frequency,
    String? timing,
    int? durationDays,
    bool clearDuration = false,
    String? stopReason,
    String? unlistedName,
    String? instructions,
  }) {
    return PrescriptionItem(
      id: id ?? this.id,
      action: action ?? this.action,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      composition: composition ?? this.composition,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      timing: timing ?? this.timing,
      durationDays: clearDuration ? null : (durationDays ?? this.durationDays),
      stopReason: stopReason ?? this.stopReason,
      unlistedName: unlistedName ?? this.unlistedName,
      instructions: instructions ?? this.instructions,
    );
  }
}
