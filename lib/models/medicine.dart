class Medicine {
  final String id;
  final String productName; // Brand name with dosage form (e.g., 'Telma 40 tablet', 'Dolo 650 tablet')
  final String composition; // Generic molecule with strength (e.g., 'Telmisartan 40mg', 'Paracetamol 650mg')
  final String?
  manufacturer; // Pharmaceutical manufacturer (e.g., 'Glenmark', 'Micro Labs')
  final String? defaultDosage; // e.g., '1 Tablet', '5 ml'
  final String? defaultFrequency; // e.g., '1-0-0 (OD)', '1-0-1 (BD)'
  final String? defaultTiming; // e.g., 'After Food', 'Before Food'
  final int?
  defaultDurationDays; // e.g., 30 (or null for chronic / to continue)
  final String? defaultDuration; // e.g., 'To continue', 'SOS', '5 days'

  const Medicine({
    required this.id,
    required this.productName,
    required this.composition,
    this.manufacturer,
    this.defaultDosage,
    this.defaultFrequency,
    this.defaultTiming,
    this.defaultDurationDays,
    this.defaultDuration,
  });

  /// The complete generic composition (strength is integral to composition).
  String get fullCompositionLabel => composition;

  /// Prominent uppercase bracketed composition header (e.g. `[TELMISARTAN 40MG]`).
  String get formattedCompositionHeader => '[${composition.toUpperCase()}]';

  /// Standard duration display string ('To continue' for chronic, 'SOS', or 'X days').
  String get durationLabel {
    if (defaultDuration != null && defaultDuration!.trim().isNotEmpty) {
      final dd = defaultDuration!.trim();
      if (dd.toUpperCase() == 'SOS') return 'SOS';
      if (dd.toLowerCase().startsWith('cont') ||
          dd.toLowerCase() == 'to continue') {
        return 'To continue';
      }
      return dd;
    }
    if (defaultDurationDays == null || defaultDurationDays! <= 0) {
      return 'To continue';
    }
    return '$defaultDurationDays days';
  }

  /// Descriptive display string.
  String get displayName => manufacturer != null && manufacturer!.isNotEmpty
      ? '$productName ($composition) [$manufacturer]'
      : '$productName ($composition)';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'composition': composition,
      if (manufacturer != null && manufacturer!.isNotEmpty)
        'manufacturer': manufacturer,
      if (defaultDosage != null && defaultDosage!.isNotEmpty)
        'defaultDosage': defaultDosage,
      if (defaultFrequency != null && defaultFrequency!.isNotEmpty)
        'defaultFrequency': defaultFrequency,
      if (defaultTiming != null && defaultTiming!.isNotEmpty)
        'defaultTiming': defaultTiming,
      if (defaultDurationDays != null)
        'defaultDurationDays': defaultDurationDays,
      if (defaultDuration != null && defaultDuration!.isNotEmpty)
        'defaultDuration': defaultDuration,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    // If legacy records contain separated strength, ensure composition contains it cleanly
    String comp = json['composition'] as String? ?? '';
    final legacyStrength = json['strength'] as String?;
    if (legacyStrength != null &&
        legacyStrength.trim().isNotEmpty &&
        !comp.toLowerCase().contains(legacyStrength.toLowerCase())) {
      comp = '$comp $legacyStrength'.trim();
    }

    return Medicine(
      id: json['id'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      composition: comp,
      manufacturer: json['manufacturer'] as String?,
      defaultDosage: json['defaultDosage'] as String?,
      defaultFrequency: json['defaultFrequency'] as String?,
      defaultTiming: json['defaultTiming'] as String?,
      defaultDurationDays: (json['defaultDurationDays'] as num?)?.toInt(),
      defaultDuration: json['defaultDuration'] as String?,
    );
  }

  Medicine copyWith({
    String? id,
    String? productName,
    String? composition,
    String? manufacturer,
    String? defaultDosage,
    String? defaultFrequency,
    String? defaultTiming,
    int? defaultDurationDays,
    String? defaultDuration,
  }) {
    return Medicine(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      composition: composition ?? this.composition,
      manufacturer: manufacturer ?? this.manufacturer,
      defaultDosage: defaultDosage ?? this.defaultDosage,
      defaultFrequency: defaultFrequency ?? this.defaultFrequency,
      defaultTiming: defaultTiming ?? this.defaultTiming,
      defaultDurationDays: defaultDurationDays ?? this.defaultDurationDays,
      defaultDuration: defaultDuration ?? this.defaultDuration,
    );
  }
}
