class Medicine {
  final String id;
  final String productName; // Commercial brand / trade name (e.g., 'Dolo 650')
  final String composition; // Generic chemical molecule (e.g., 'Paracetamol')
  final String strength; // Molecule strength (e.g., '650 mg')
  final String form; // Dosage form (e.g., 'Tablet', 'Syrup', 'Capsule')
  final String? manufacturer; // e.g., 'Micro Labs'
  final String? category; // e.g., 'Analgesic / Antipyretic'

  const Medicine({
    required this.id,
    required this.productName,
    required this.composition,
    required this.strength,
    required this.form,
    this.manufacturer,
    this.category,
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
  }) {
    return Medicine(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      composition: composition ?? this.composition,
      strength: strength ?? this.strength,
      form: form ?? this.form,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
    );
  }
}
