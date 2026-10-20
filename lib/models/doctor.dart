import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/formatters.dart';

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
  final String?
  medicalRegNumber; // State Medical Council / NMC Reg No. (e.g. 'AMC-24891')
  final String shiftTiming; // e.g. '6:00 PM – 8:30 PM'
  final int dailyTokenLimit; // Daily token cap (default: 18)
  final bool isActive; // Operational status (true = active, false = retired/inactive)
  final int doctorSharePercentage; // Revenue split percentage (0 to 100, default: 100)

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
    this.shiftTiming = '6:00 PM – 8:30 PM',
    this.dailyTokenLimit = 18,
    this.isActive = true,
    this.doctorSharePercentage = 100,
  });

  /// Canonical display title with prefix (e.g. 'Dr. Bhaskar Thakuria').
  String get titleName => AppFormatters.doctorTitle(name);

  /// Clean doctor name without title prefix (e.g. 'Bhaskar Thakuria').
  String get cleanName => AppFormatters.cleanDoctorName(name);

  /// Formatted schedule string: e.g. 'Mon, Wed, Fri • 6:00 PM – 8:30 PM'
  String get formattedSchedule {
    final days = availableDays.isNotEmpty
        ? availableDays.join(', ')
        : 'Mon, Wed, Fri';
    final timing = shiftTiming.isNotEmpty ? shiftTiming : '6:00 PM – 8:30 PM';
    return '$days • $timing';
  }

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
      'shiftTiming': shiftTiming,
      'dailyTokenLimit': dailyTokenLimit,
      'isActive': isActive,
      'doctorSharePercentage': doctorSharePercentage,
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
          (json['blockedDates'] as List<dynamic>?)
              ?.map((d) {
                if (d is Timestamp) return d.toDate();
                if (d is DateTime) return d;
                if (d is String) return DateTime.tryParse(d);
                return null;
              })
              .whereType<DateTime>()
              .toList() ??
          [],
      pin: json['pin'] as String? ?? '1234',
      consultationFee: (json['consultationFee'] as num?)?.toInt() ?? 500,
      freeReviewDays: (json['freeReviewDays'] as num?)?.toInt() ?? 14,
      searchPreference: json['searchPreference'] as String? ?? 'brandFirst',
      medicalRegNumber: json['medicalRegNumber'] as String?,
      shiftTiming: json['shiftTiming'] as String? ?? '6:00 PM – 8:30 PM',
      dailyTokenLimit: (json['dailyTokenLimit'] as num?)?.toInt() ?? 18,
      isActive: json['isActive'] as bool? ?? true,
      doctorSharePercentage:
          (json['doctorSharePercentage'] as num?)?.toInt() ?? 100,
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
    String? shiftTiming,
    int? dailyTokenLimit,
    bool? isActive,
    int? doctorSharePercentage,
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
      shiftTiming: shiftTiming ?? this.shiftTiming,
      dailyTokenLimit: dailyTokenLimit ?? this.dailyTokenLimit,
      isActive: isActive ?? this.isActive,
      doctorSharePercentage:
          doctorSharePercentage ?? this.doctorSharePercentage,
    );
  }
}
