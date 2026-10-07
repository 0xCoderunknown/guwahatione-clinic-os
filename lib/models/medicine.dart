class Medicine {
  final String id;
  final String productName; // Commercial brand / trade name (e.g., 'Dolo 650')
  final String composition; // Generic chemical molecule (e.g., 'Paracetamol')
  final String strength; // Molecule strength (e.g., '650 mg')
  final String form; // Dosage form (e.g., 'Tablet', 'Syrup', 'Capsule')
  final String? manufacturer; // e.g., 'Micro Labs'
  final String? category; // e.g., 'Analgesic / Antipyretic'
  final String? defaultDosage; // e.g., '1 Tablet', '5 ml'
  final String? defaultFrequency; // e.g., '1-0-0 (OD)', '1-0-1 (BD)'
  final String? defaultTiming; // e.g., 'After Food', 'Before Food'
  final int? defaultDurationDays; // e.g., 30 (or null for continuous)

  const Medicine({
    required this.id,
    required this.productName,
    required this.composition,
    required this.strength,
    required this.form,
    this.manufacturer,
    this.category,
    this.defaultDosage,
    this.defaultFrequency,
    this.defaultTiming,
    this.defaultDurationDays,
  });

  String get fullCompositionLabel => '$composition $strength'.trim();

  String get displayName => '$productName ($fullCompositionLabel) [$form]';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'composition': composition,
      'strength': strength,
      'form': form,
      'manufacturer': manufacturer,
      'category': category,
      if (defaultDosage != null) 'defaultDosage': defaultDosage,
      if (defaultFrequency != null) 'defaultFrequency': defaultFrequency,
      if (defaultTiming != null) 'defaultTiming': defaultTiming,
      if (defaultDurationDays != null) 'defaultDurationDays': defaultDurationDays,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      composition: json['composition'] as String? ?? '',
      strength: json['strength'] as String? ?? '',
      form: json['form'] as String? ?? 'Tablet',
      manufacturer: json['manufacturer'] as String?,
      category: json['category'] as String?,
      defaultDosage: json['defaultDosage'] as String?,
      defaultFrequency: json['defaultFrequency'] as String?,
      defaultTiming: json['defaultTiming'] as String?,
      defaultDurationDays: (json['defaultDurationDays'] as num?)?.toInt(),
    );
  }

  Medicine copyWith({
    String? id,
    String? productName,
    String? composition,
    String? strength,
    String? form,
    String? manufacturer,
    String? category,
    String? defaultDosage,
    String? defaultFrequency,
    String? defaultTiming,
    int? defaultDurationDays,
  }) {
    return Medicine(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      composition: composition ?? this.composition,
      strength: strength ?? this.strength,
      form: form ?? this.form,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      defaultDosage: defaultDosage ?? this.defaultDosage,
      defaultFrequency: defaultFrequency ?? this.defaultFrequency,
      defaultTiming: defaultTiming ?? this.defaultTiming,
      defaultDurationDays: defaultDurationDays ?? this.defaultDurationDays,
    );
  }
}
