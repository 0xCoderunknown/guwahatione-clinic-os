class Patient {
  final String id; // Phone number is the key ID
  final String name;
  final int age;
  final String gender; // 'Male', 'Female', 'Other', 'Unspecified'
  final List<String> allergies; // Prominent clinical alerts
  final DateTime lastVisitDate;
  final String phoneNumber;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    this.gender = 'Unspecified',
    this.allergies = const [],
    required this.lastVisitDate,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'allergies': allergies,
      'lastVisitDate': lastVisitDate.toIso8601String(),
      'phoneNumber': phoneNumber,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Patient',
      // Firestore can return numeric fields as num (int or double), so we
      // cast to num first and then convert to int to avoid type errors.
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String? ?? 'Unspecified',
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastVisitDate: json['lastVisitDate'] != null
          ? DateTime.parse(json['lastVisitDate'] as String)
          : DateTime.now(),
      phoneNumber: json['phoneNumber'] as String? ?? '',
    );
  }

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    List<String>? allergies,
    DateTime? lastVisitDate,
    String? phoneNumber,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      allergies: allergies ?? this.allergies,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
