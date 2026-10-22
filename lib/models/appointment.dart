import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  pending,
  completed,
  absent;

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.absent:
        return 'Absent';
    }
  }
}

enum VisitStatus {
  booked, // Reserved over phone / advance, not yet at desk
  waitingInLobby, // Physically checked in at desk, ready for chamber
  inConsultation, // Currently with doctor
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case VisitStatus.booked:
        return 'Booked (Advance)';
      case VisitStatus.waitingInLobby:
        return 'In Lobby';
      case VisitStatus.inConsultation:
        return 'In Consultation';
      case VisitStatus.completed:
        return 'Completed';
      case VisitStatus.cancelled:
        return 'Cancelled / Absent';
    }
  }

  bool get isWaitingInChamberQueue =>
      this == VisitStatus.waitingInLobby || this == VisitStatus.inConsultation;

  bool get isCheckedIn => this != VisitStatus.booked;
}

enum PaymentType {
  paidCash,
  paidUpi,
  paidCarryOver, // Prepaid prior-date visit carried forward (₹0 fresh collection)
  freeReview, // 14-day statutory return
  freeFamily, // Discretionary doctor/clinic waiver (MUST NOT be overridden)
  postPay, // Pay on exit / post-consultation
  unpaid; // Booked over phone, not yet collected

  String get displayName {
    switch (this) {
      case PaymentType.paidCash:
        return 'Paid (Cash)';
      case PaymentType.paidUpi:
        return 'Paid (UPI)';
      case PaymentType.paidCarryOver:
        return 'Paid (Carry-Over)';
      case PaymentType.freeReview:
        return 'Free (Review)';
      case PaymentType.freeFamily:
        return 'Free (Family)';
      case PaymentType.postPay:
        return 'Post-Pay';
      case PaymentType.unpaid:
        return 'Unpaid';
    }
  }

  bool get isPaid =>
      this == PaymentType.paidCash ||
      this == PaymentType.paidUpi ||
      this == PaymentType.paidCarryOver;

  bool get isFree =>
      this == PaymentType.freeReview || this == PaymentType.freeFamily;
}

class Appointment {
  final String id;
  final String
  patientId; // Unique patient ID (defaults to patientPhone for legacy records)
  final String patientPhone;
  final String patientName;
  final String? guardianName; // Optional parent / guardian name
  final String? guardianRelation; // e.g., 'Mother', 'Father'
  final String? patientAgeDisplay; // Exact age snapshot at booking time (e.g., '4 Months', '32 Years')
  final VisitStatus visitStatus;
  final PaymentType paymentType;
  final int amountCollected;
  final int queueNumber;
  final DateTime scheduledDate;
  final String doctorId;
  final String doctorName;
  final DateTime? checkedInAt;
  final bool isPaused; // Indicates an in-progress consultation was paused/saved as draft
  final String? refundStatus; // 'none', 'pending_refund', 'refunded', 'carried_forward'
  final String? carriedOverAppointmentId; // Reference to prior un-consulted paid appointment
  final int? carriedOverAmount; // Amount originally paid on the prior appointment
  final DateTime? carriedOverDate; // Calendar date of originating appointment

  AppointmentStatus get status {
    switch (visitStatus) {
      case VisitStatus.completed:
        return AppointmentStatus.completed;
      case VisitStatus.cancelled:
        return AppointmentStatus.absent;
      case VisitStatus.booked:
      case VisitStatus.waitingInLobby:
      case VisitStatus.inConsultation:
        return AppointmentStatus.pending;
    }
  }

  /// Effective consultation fee earned by doctor / clinic for this visit.
  /// For carried-over visits where ₹0 was collected today, resolves to carriedOverAmount.
  int get effectiveFee =>
      paymentType == PaymentType.paidCarryOver
          ? (carriedOverAmount ?? 0)
          : amountCollected;

  /// Formats clean, human-friendly payment summary without bracket clutter.
  /// Examples: "₹500 Paid", "Free Review", "Free Waiver", "Post-Pay", "Unpaid", "₹500 Paid (Carry-Over)".
  String get paymentSummary {
    switch (paymentType) {
      case PaymentType.paidCash:
      case PaymentType.paidUpi:
        return '₹$amountCollected Paid';
      case PaymentType.paidCarryOver:
        return '₹${carriedOverAmount ?? 0} Paid (Carry-Over)';
      case PaymentType.freeReview:
        return 'Free Review';
      case PaymentType.freeFamily:
        return 'Free Waiver';
      case PaymentType.postPay:
        return 'Post-Pay';
      case PaymentType.unpaid:
        return 'Unpaid';
    }
  }

  Appointment({
    required this.id,
    String? patientId,
    required this.patientPhone,
    required this.patientName,
    this.guardianName,
    this.guardianRelation,
    this.patientAgeDisplay,
    VisitStatus? visitStatus,
    AppointmentStatus? status,
    required this.paymentType,
    required this.amountCollected,
    required this.queueNumber,
    required this.scheduledDate,
    required this.doctorId,
    required this.doctorName,
    this.checkedInAt,
    this.isPaused = false,
    this.refundStatus = 'none',
    this.carriedOverAppointmentId,
    this.carriedOverAmount,
    this.carriedOverDate,
  }) : patientId = patientId ?? patientPhone,
       visitStatus =
           visitStatus ??
           (status != null
               ? _visitStatusFromAppointmentStatus(status)
               : VisitStatus.waitingInLobby);

  static VisitStatus _visitStatusFromAppointmentStatus(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.completed:
        return VisitStatus.completed;
      case AppointmentStatus.absent:
        return VisitStatus.cancelled;
      case AppointmentStatus.pending:
        return VisitStatus.waitingInLobby;
    }
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? patientPhone,
    String? patientName,
    String? guardianName,
    String? guardianRelation,
    String? patientAgeDisplay,
    VisitStatus? visitStatus,
    AppointmentStatus? status,
    PaymentType? paymentType,
    int? amountCollected,
    int? queueNumber,
    DateTime? scheduledDate,
    String? doctorId,
    String? doctorName,
    DateTime? checkedInAt,
    bool? isPaused,
    String? refundStatus,
    String? carriedOverAppointmentId,
    int? carriedOverAmount,
    DateTime? carriedOverDate,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientPhone: patientPhone ?? this.patientPhone,
      patientName: patientName ?? this.patientName,
      guardianName: guardianName ?? this.guardianName,
      guardianRelation: guardianRelation ?? this.guardianRelation,
      patientAgeDisplay: patientAgeDisplay ?? this.patientAgeDisplay,
      visitStatus:
          visitStatus ??
          (status != null
              ? _visitStatusFromAppointmentStatus(status)
              : this.visitStatus),
      paymentType: paymentType ?? this.paymentType,
      amountCollected: amountCollected ?? this.amountCollected,
      queueNumber: queueNumber ?? this.queueNumber,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      isPaused: isPaused ?? this.isPaused,
      refundStatus: refundStatus ?? this.refundStatus,
      carriedOverAppointmentId:
          carriedOverAppointmentId ?? this.carriedOverAppointmentId,
      carriedOverAmount: carriedOverAmount ?? this.carriedOverAmount,
      carriedOverDate: carriedOverDate ?? this.carriedOverDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientPhone': patientPhone,
      'patientName': patientName,
      if (guardianName != null && guardianName!.trim().isNotEmpty)
        'guardianName': guardianName!.trim(),
      if (guardianRelation != null && guardianRelation!.trim().isNotEmpty)
        'guardianRelation': guardianRelation!.trim(),
      if (patientAgeDisplay != null && patientAgeDisplay!.trim().isNotEmpty)
        'patientAgeDisplay': patientAgeDisplay!.trim(),
      'status': status.name,
      'visitStatus': visitStatus.name,
      'paymentType': paymentType.name,
      'amountCollected': amountCollected,
      'queueNumber': queueNumber,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'doctorId': doctorId,
      'doctorName': doctorName,
      if (checkedInAt != null) 'checkedInAt': Timestamp.fromDate(checkedInAt!),
      if (isPaused) 'isPaused': true,
      if (refundStatus != null && refundStatus != 'none')
        'refundStatus': refundStatus,
      if (carriedOverAppointmentId != null &&
          carriedOverAppointmentId!.trim().isNotEmpty)
        'carriedOverAppointmentId': carriedOverAppointmentId!.trim(),
      if (carriedOverAmount != null && carriedOverAmount! > 0)
        'carriedOverAmount': carriedOverAmount,
      if (carriedOverDate != null)
        'carriedOverDate': Timestamp.fromDate(carriedOverDate!),
    };
  }

  /// JSON-safe serialization map (using ISO string instead of Firestore Timestamp)
  /// specifically for offline cache persistence in SharedPreferences.
  Map<String, dynamic> toCacheMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientPhone': patientPhone,
      'patientName': patientName,
      if (guardianName != null && guardianName!.trim().isNotEmpty)
        'guardianName': guardianName!.trim(),
      if (guardianRelation != null && guardianRelation!.trim().isNotEmpty)
        'guardianRelation': guardianRelation!.trim(),
      if (patientAgeDisplay != null && patientAgeDisplay!.trim().isNotEmpty)
        'patientAgeDisplay': patientAgeDisplay!.trim(),
      'status': status.name,
      'visitStatus': visitStatus.name,
      'paymentType': paymentType.name,
      'amountCollected': amountCollected,
      'queueNumber': queueNumber,
      'scheduledDate': scheduledDate.toIso8601String(),
      'doctorId': doctorId,
      'doctorName': doctorName,
      if (checkedInAt != null) 'checkedInAt': checkedInAt!.toIso8601String(),
      if (isPaused) 'isPaused': true,
      if (refundStatus != null && refundStatus != 'none')
        'refundStatus': refundStatus,
      if (carriedOverAppointmentId != null &&
          carriedOverAppointmentId!.trim().isNotEmpty)
        'carriedOverAppointmentId': carriedOverAppointmentId!.trim(),
      if (carriedOverAmount != null && carriedOverAmount! > 0)
        'carriedOverAmount': carriedOverAmount,
      if (carriedOverDate != null)
        'carriedOverDate': carriedOverDate!.toIso8601String(),
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['scheduledDate'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? parsedCheckedInAt;
    final rawChecked = json['checkedInAt'];
    if (rawChecked is Timestamp) {
      parsedCheckedInAt = rawChecked.toDate();
    } else if (rawChecked is DateTime) {
      parsedCheckedInAt = rawChecked;
    } else if (rawChecked is String) {
      parsedCheckedInAt = DateTime.tryParse(rawChecked);
    }

    DateTime? parsedCarriedOverDate;
    final rawCarriedDate = json['carriedOverDate'];
    if (rawCarriedDate is Timestamp) {
      parsedCarriedOverDate = rawCarriedDate.toDate();
    } else if (rawCarriedDate is DateTime) {
      parsedCarriedOverDate = rawCarriedDate;
    } else if (rawCarriedDate is String) {
      parsedCarriedOverDate = DateTime.tryParse(rawCarriedDate);
    }

    VisitStatus visitStatus;
    if (json['visitStatus'] != null) {
      visitStatus = VisitStatus.values.firstWhere(
        (e) => e.name == json['visitStatus'],
        orElse: () => VisitStatus.waitingInLobby,
      );
    } else {
      final st = json['status'];
      if (st == 'completed') {
        visitStatus = VisitStatus.completed;
      } else if (st == 'absent') {
        visitStatus = VisitStatus.cancelled;
      } else {
        visitStatus = VisitStatus.waitingInLobby;
      }
    }

    // Single source of truth reconciliation: ensure terminal status states never desync
    final st = json['status'];
    if (st == 'completed' && visitStatus != VisitStatus.completed) {
      visitStatus = VisitStatus.completed;
    } else if (st == 'absent' && visitStatus != VisitStatus.cancelled) {
      visitStatus = VisitStatus.cancelled;
    }

    PaymentType paymentType;
    if (json['paymentType'] != null) {
      final pStr = json['paymentType'] as String;
      if (pStr == 'paid') {
        paymentType = PaymentType.paidCash;
      } else {
        paymentType = PaymentType.values.firstWhere(
          (e) => e.name == pStr,
          orElse: () => PaymentType.paidCash,
        );
      }
    } else {
      paymentType = PaymentType.paidCash;
    }

    final phone = json['patientPhone'] as String? ?? '';
    final patientId = json['patientId'] as String? ?? phone;
    final isPaused = json['isPaused'] as bool? ?? false;
    final refundStatus = json['refundStatus'] as String? ?? 'none';
    final carriedOverAppointmentId =
        json['carriedOverAppointmentId'] as String?;
    final carriedOverAmount =
        (json['carriedOverAmount'] as num?)?.toInt();

    return Appointment(
      id: json['id'] as String? ?? '',
      patientId: patientId,
      patientPhone: phone,
      patientName: json['patientName'] as String? ?? '',
      guardianName: json['guardianName'] as String?,
      guardianRelation: json['guardianRelation'] as String?,
      patientAgeDisplay: json['patientAgeDisplay'] as String?,
      visitStatus: visitStatus,
      paymentType: paymentType,
      amountCollected: (json['amountCollected'] as num?)?.toInt() ?? 0,
      queueNumber: (json['queueNumber'] as num?)?.toInt() ?? 0,
      scheduledDate: parsedDate,
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      checkedInAt: parsedCheckedInAt,
      isPaused: isPaused,
      refundStatus: refundStatus,
      carriedOverAppointmentId: carriedOverAppointmentId,
      carriedOverAmount: carriedOverAmount,
      carriedOverDate: parsedCarriedOverDate,
    );
  }
}
