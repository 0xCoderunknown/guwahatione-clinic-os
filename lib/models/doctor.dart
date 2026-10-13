import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String phone;
  final List<String> availableDays; // e.g., ["Mon", "Wed", "Fri"]
  final List<DateTime> blockedDates; // Days they are on leave
  final String pin; // 4-digit PIN for chamber access
  final int consultationFee; // Default consultation fee in INR
  final int freeReviewDays; // Free review policy window in days (0 to 30; 0 = no free review)
  final String searchPreference; // 'brandFirst' | 'compositionFirst'
  final String? medicalRegNumber; // State Medical Council / NMC Reg No. (e.g. 'AMC-24891')

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.phone,
    required this.availableDays,
    required this.blockedDates,
    this.pin = '1234',
    this.consultationFee = 500,
    this.freeReviewDays = 14,
    this.searchPreference = 'brandFirst',
    this.medicalRegNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'phone': phone,
      'availableDays': availableDays,
      'blockedDates': blockedDates.map((d) => d.toIso8601String()).toList(),
      'pin': pin,
      'consultationFee': consultationFee,
      'freeReviewDays': freeReviewDays,
      'searchPreference': searchPreference,
      'medicalRegNumber': medicalRegNumber,
    };
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Doctor',
      specialty: json['specialty'] as String? ?? 'General',
      phone: json['phone'] as String? ?? '',
      availableDays: List<String>.from(json['availableDays'] ?? []),
      blockedDates:
          (json['blockedDates'] as List<dynamic>?)?.map((d) {
            if (d is Timestamp) return d.toDate();
            if (d is DateTime) return d;
            if (d is String) return DateTime.tryParse(d);
            return null;
          }).whereType<DateTime>().toList() ??
          [],
      pin: json['pin'] as String? ?? '1234',
      consultationFee: (json['consultationFee'] as num?)?.toInt() ?? 500,
      freeReviewDays: (json['freeReviewDays'] as num?)?.toInt() ?? 14,
      searchPreference: json['searchPreference'] as String? ?? 'brandFirst',
      medicalRegNumber: json['medicalRegNumber'] as String?,
    );
  }

  Doctor copyWith({
    String? id,
    String? name,
    String? specialty,
    String? phone,
    List<String>? availableDays,
    List<DateTime>? blockedDates,
    String? pin,
    int? consultationFee,
    int? freeReviewDays,
    String? searchPreference,
    String? medicalRegNumber,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      phone: phone ?? this.phone,
      availableDays: availableDays ?? this.availableDays,
      blockedDates: blockedDates ?? this.blockedDates,
      pin: pin ?? this.pin,
      consultationFee: consultationFee ?? this.consultationFee,
      freeReviewDays: freeReviewDays ?? this.freeReviewDays,
      searchPreference: searchPreference ?? this.searchPreference,
      medicalRegNumber: medicalRegNumber ?? this.medicalRegNumber,
    );
  }
}

