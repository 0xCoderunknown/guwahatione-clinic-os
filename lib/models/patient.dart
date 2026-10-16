import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id; // Unique patient identifier (UUID / pat_* / legacy phone)
  final String name;
  final int age; // Age in whole years
  final int? ageMonths; // Age in months for infants (< 2 years)
  final int? ageDays; // Age in days for neonates (< 1 month)
  final DateTime? dateOfBirth;
  final String gender; // 'Male', 'Female', 'Other'
  final List<String> allergies; // Prominent clinical alerts
  final DateTime? lastVisitDate;
  final String phoneNumber; // Primary contact / household phone number
  final String? guardianName; // Optional parent / guardian name
  final String?
  guardianRelation; // e.g., 'Mother', 'Father', 'Spouse', 'Son', 'Guardian'
  final bool isLegacy; // Indicates un-disambiguated legacy phone-keyed record

  Patient({
    required this.id,
    required this.name,
    required this.age,
    this.ageMonths,
    this.ageDays,
    this.dateOfBirth,
    required this.gender,
    this.allergies = const [],
    this.lastVisitDate,
    required this.phoneNumber,
    this.guardianName,
    this.guardianRelation,
    this.isLegacy = false,
  });

  /// Human-readable clinical age display (e.g., '4 Months', '18 Days', '34 Years').
  String get formattedAge {
    if (ageMonths != null && ageMonths! > 0) {
      return '$ageMonths Month${ageMonths == 1 ? '' : 's'}';
    }
    if (ageDays != null && ageDays! > 0) {
      return '$ageDays Day${ageDays == 1 ? '' : 's'}';
    }
    if (age > 0) {
      return '$age Year${age == 1 ? '' : 's'}';
    }
    if (ageMonths == 0 && ageDays != null) {
      return '$ageDays Day${ageDays == 1 ? '' : 's'}';
    }
    return '$age Years';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'age': age,
      if (ageMonths != null) 'ageMonths': ageMonths,
      if (ageDays != null) 'ageDays': ageDays,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      'gender': gender,
      'allergies': allergies,
      'phoneNumber': phoneNumber,
      if (guardianName != null && guardianName!.trim().isNotEmpty)
        'guardianName': guardianName!.trim(),
      if (guardianRelation != null && guardianRelation!.trim().isNotEmpty)
        'guardianRelation': guardianRelation!.trim(),
      if (isLegacy) 'isLegacy': true,
    };
    if (lastVisitDate != null) {
      data['lastVisitDate'] = lastVisitDate!.toIso8601String();
    }
    return data;
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    final phone =
        json['phoneNumber'] as String? ??
        json['phone'] as String? ??
        json['patientPhone'] as String? ??
        json['id'] as String? ??
        '';

    final id = json['id'] as String? ?? (phone.isNotEmpty ? phone : 'unknown');

    DateTime? parsedLastVisit;
    final rawVisit = json['lastVisitDate'];
    if (rawVisit is Timestamp) {
      parsedLastVisit = rawVisit.toDate();
    } else if (rawVisit is String) {
      parsedLastVisit = DateTime.tryParse(rawVisit);
    } else if (rawVisit is DateTime) {
      parsedLastVisit = rawVisit;
    }

    DateTime? parsedDob;
    final rawDob = json['dateOfBirth'];
    if (rawDob is Timestamp) {
      parsedDob = rawDob.toDate();
    } else if (rawDob is String) {
      parsedDob = DateTime.tryParse(rawDob);
    } else if (rawDob is DateTime) {
      parsedDob = rawDob;
    }

    final rawGender = json['gender'] as String? ?? 'Male';
    final normalizedGender = (rawGender.toLowerCase() == 'female')
        ? 'Female'
        : (rawGender.toLowerCase() == 'other')
        ? 'Other'
        : 'Male';

    final isLegacyRecord =
        json['isLegacy'] as bool? ?? (id == phone && phone.isNotEmpty);

    return Patient(
      id: id,
      name: json['name'] as String? ?? 'Unknown Patient',
      age: (json['age'] as num?)?.toInt() ?? 0,
      ageMonths: (json['ageMonths'] as num?)?.toInt(),
      ageDays: (json['ageDays'] as num?)?.toInt(),
      dateOfBirth: parsedDob,
      gender: normalizedGender,
      allergies:
          (json['allergies'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList() ??
          const [],
      lastVisitDate: parsedLastVisit,
      phoneNumber: phone,
      guardianName: json['guardianName'] as String?,
      guardianRelation: json['guardianRelation'] as String?,
      isLegacy: isLegacyRecord,
    );
  }

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    int? ageMonths,
    int? ageDays,
    DateTime? dateOfBirth,
    String? gender,
    List<String>? allergies,
    DateTime? lastVisitDate,
    String? phoneNumber,
    String? guardianName,
    String? guardianRelation,
    bool? isLegacy,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      ageMonths: ageMonths ?? this.ageMonths,
      ageDays: ageDays ?? this.ageDays,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      allergies: allergies ?? this.allergies,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      guardianName: guardianName ?? this.guardianName,
      guardianRelation: guardianRelation ?? this.guardianRelation,
      isLegacy: isLegacy ?? this.isLegacy,
    );
  }
}
