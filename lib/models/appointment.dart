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
  booked,          // Reserved over phone / advance, not yet at desk
  waitingInLobby,  // Physically checked in at desk, ready for chamber
  inConsultation,  // Currently with doctor
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
  freeReview, // 14-day statutory return
  freeFamily, // Discretionary doctor/clinic waiver (MUST NOT be overridden)
  postPay,    // Pay on exit / post-consultation
  unpaid;     // Booked over phone, not yet collected

  String get displayName {
    switch (this) {
      case PaymentType.paidCash:
        return 'Paid (Cash)';
      case PaymentType.paidUpi:
        return 'Paid (UPI)';
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
      this == PaymentType.paidCash || this == PaymentType.paidUpi;

  bool get isFree =>
      this == PaymentType.freeReview || this == PaymentType.freeFamily;
}

class Appointment {
  final String id;
  final String patientPhone;
  final String patientName;
  final VisitStatus visitStatus;
  final PaymentType paymentType;
  final int amountCollected;
  final int queueNumber;
  final DateTime scheduledDate;
  final String doctorId;
  final String doctorName;
  final DateTime? checkedInAt;

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

  Appointment({
    required this.id,
    required this.patientPhone,
    required this.patientName,
    VisitStatus? visitStatus,
    AppointmentStatus? status,
    required this.paymentType,
    required this.amountCollected,
    required this.queueNumber,
    required this.scheduledDate,
    required this.doctorId,
    required this.doctorName,
    this.checkedInAt,
  }) : visitStatus = visitStatus ??
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
    String? patientPhone,
    String? patientName,
    VisitStatus? visitStatus,
    AppointmentStatus? status,
    PaymentType? paymentType,
    int? amountCollected,
    int? queueNumber,
    DateTime? scheduledDate,
    String? doctorId,
    String? doctorName,
    DateTime? checkedInAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientPhone: patientPhone ?? this.patientPhone,
      patientName: patientName ?? this.patientName,
      visitStatus: visitStatus ??
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientPhone': patientPhone,
      'patientName': patientName,
      'status': status.name,
      'visitStatus': visitStatus.name,
      'paymentType': paymentType.name,
      'amountCollected': amountCollected,
      'queueNumber': queueNumber,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'doctorId': doctorId,
      'doctorName': doctorName,
      if (checkedInAt != null) 'checkedInAt': Timestamp.fromDate(checkedInAt!),
    };
  }

  /// JSON-safe serialization map (using ISO string instead of Firestore Timestamp)
  /// specifically for offline cache persistence in SharedPreferences.
  Map<String, dynamic> toCacheMap() {
    return {
      'id': id,
      'patientPhone': patientPhone,
      'patientName': patientName,
      'status': status.name,
      'visitStatus': visitStatus.name,
      'paymentType': paymentType.name,
      'amountCollected': amountCollected,
      'queueNumber': queueNumber,
      'scheduledDate': scheduledDate.toIso8601String(),
      'doctorId': doctorId,
      'doctorName': doctorName,
      if (checkedInAt != null) 'checkedInAt': checkedInAt!.toIso8601String(),
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

    return Appointment(
      id: json['id'] as String? ?? '',
      patientPhone: json['patientPhone'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      visitStatus: visitStatus,
      paymentType: paymentType,
      amountCollected: (json['amountCollected'] as num?)?.toInt() ?? 0,
      queueNumber: (json['queueNumber'] as num?)?.toInt() ?? 0,
      scheduledDate: parsedDate,
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      checkedInAt: parsedCheckedInAt,
    );
  }
}
