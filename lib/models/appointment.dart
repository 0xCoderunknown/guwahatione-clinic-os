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

enum PaymentType {
  paid,
  freeReview,
  freeFamily;

  String get displayName {
    switch (this) {
      case PaymentType.paid:
        return 'Paid';
      case PaymentType.freeReview:
        return 'Free (Review)';
      case PaymentType.freeFamily:
        return 'Free (Family)';
    }
  }
}

class Appointment {
  final String id;
  final String patientPhone;
  final String patientName;
  final AppointmentStatus status;
  final PaymentType paymentType;
  final int amountCollected;
  final int queueNumber;
  final DateTime scheduledDate;
  final String doctorId;
  final String doctorName;

  Appointment({
    required this.id,
    required this.patientPhone,
    required this.patientName,
    required this.status,
    required this.paymentType,
    required this.amountCollected,
    required this.queueNumber,
    required this.scheduledDate,
    required this.doctorId,
    required this.doctorName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientPhone': patientPhone,
      'patientName': patientName,
      'status': status.name,
      'paymentType': paymentType.name,
      'amountCollected': amountCollected,
      'queueNumber': queueNumber,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'doctorId': doctorId,
      'doctorName': doctorName,
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

    return Appointment(
      id: json['id'] as String? ?? '',
      patientPhone: json['patientPhone'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      paymentType: PaymentType.values.firstWhere(
        (e) => e.name == json['paymentType'],
        orElse: () => PaymentType.paid,
      ),
      amountCollected: (json['amountCollected'] as num?)?.toInt() ?? 0,
      queueNumber: (json['queueNumber'] as num?)?.toInt() ?? 0,
      scheduledDate: parsedDate,
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
    );
  }
}
