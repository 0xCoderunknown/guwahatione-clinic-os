class Patient {
  final String id; // Phone number is the key ID
  final String name;
  final int age;
  final String gender; // 'Male', 'Female', 'Other'
  final List<String> allergies; // Prominent clinical alerts
  final DateTime? lastVisitDate;
  final String phoneNumber;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.allergies = const [],
    this.lastVisitDate,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'allergies': allergies,
      'phoneNumber': phoneNumber,
    };
    if (lastVisitDate != null) {
      data['lastVisitDate'] = lastVisitDate!.toIso8601String();
    }
    return data;
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String,
      age: (json['age'] as num).toInt(),
      gender: json['gender'] as String,
      allergies:
          (json['allergies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastVisitDate: json['lastVisitDate'] is String
          ? DateTime.parse(json['lastVisitDate'] as String)
          : null,
      phoneNumber: json['phoneNumber'] as String,
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
