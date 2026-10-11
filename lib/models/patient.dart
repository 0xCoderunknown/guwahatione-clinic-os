import 'package:cloud_firestore/cloud_firestore.dart';

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
    final phone = json['phoneNumber'] as String? ??
        json['phone'] as String? ??
        json['patientPhone'] as String? ??
        json['id'] as String? ??
        '';

    DateTime? parsedLastVisit;
    final rawVisit = json['lastVisitDate'];
    if (rawVisit is Timestamp) {
      parsedLastVisit = rawVisit.toDate();
    } else if (rawVisit is String) {
      parsedLastVisit = DateTime.tryParse(rawVisit);
    } else if (rawVisit is DateTime) {
      parsedLastVisit = rawVisit;
    }

    final rawGender = json['gender'] as String? ?? 'Male';
    final normalizedGender = (rawGender.toLowerCase() == 'female')
        ? 'Female'
        : (rawGender.toLowerCase() == 'other')
            ? 'Other'
            : 'Male';

    return Patient(
      id: json['id'] as String? ?? (phone.isNotEmpty ? phone : 'unknown'),
      name: json['name'] as String? ?? 'Unknown Patient',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: normalizedGender,
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastVisitDate: parsedLastVisit,
      phoneNumber: phone,
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
