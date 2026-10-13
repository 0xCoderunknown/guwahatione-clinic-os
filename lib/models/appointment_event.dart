import 'package:cloud_firestore/cloud_firestore.dart';

import 'appointment.dart';

/// Enumeration of distinct appointment lifecycle audit events.
enum AppointmentEventType {
  created,
  checkedIn,
  admitted,
  completed,
  markedAbsent,
  statusUpdated,
}

/// Immutable forensic audit ledger entry for appointment state transitions.
///
/// Invariant: Once written, appointment events can NEVER be updated or deleted.
class AppointmentEvent {
  final String id;
  final String appointmentId;
  final AppointmentEventType eventType;
  final VisitStatus visitStatus;
  final int? amountCollected;
  final PaymentType? paymentType;
  final String actorRole;
  final DateTime timestamp;
  final String? note;

  const AppointmentEvent({
    required this.id,
    required this.appointmentId,
    required this.eventType,
    required this.visitStatus,
    this.amountCollected,
    this.paymentType,
    required this.actorRole,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'eventType': eventType.name,
      'visitStatus': visitStatus.name,
      if (amountCollected != null) 'amountCollected': amountCollected,
      if (paymentType != null) 'paymentType': paymentType!.name,
      'actorRole': actorRole,
      'timestamp': Timestamp.fromDate(timestamp),
      if (note != null) 'note': note,
    };
  }

  factory AppointmentEvent.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp;
    final rawTs = json['timestamp'];
    if (rawTs is Timestamp) {
      parsedTimestamp = rawTs.toDate();
    } else if (rawTs is DateTime) {
      parsedTimestamp = rawTs;
    } else if (rawTs is String) {
      parsedTimestamp = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now();
    }

    final eventType = AppointmentEventType.values.firstWhere(
      (e) => e.name == json['eventType'],
      orElse: () => AppointmentEventType.statusUpdated,
    );

    final visitStatus = VisitStatus.values.firstWhere(
      (e) => e.name == json['visitStatus'],
      orElse: () => VisitStatus.waitingInLobby,
    );

    PaymentType? paymentType;
    if (json['paymentType'] != null) {
      paymentType = PaymentType.values.firstWhere(
        (e) => e.name == json['paymentType'],
        orElse: () => PaymentType.paidCash,
      );
    }

    return AppointmentEvent(
      id: json['id'] as String? ?? '',
      appointmentId: json['appointmentId'] as String? ?? '',
      eventType: eventType,
      visitStatus: visitStatus,
      amountCollected: (json['amountCollected'] as num?)?.toInt(),
      paymentType: paymentType,
      actorRole: json['actorRole'] as String? ?? 'receptionist',
      timestamp: parsedTimestamp,
      note: json['note'] as String?,
    );
  }
}
