/// Strongly typed domain status for chamber operational state.
enum ChamberStatus {
  idle,
  readyForNext,
  calling,
  inConsultation,
  consultationEnded,
  shiftEnded;

  static ChamberStatus fromString(String? val) {
    switch (val) {
      case 'ready_for_next':
        return ChamberStatus.readyForNext;
      case 'calling':
        return ChamberStatus.calling;
      case 'in_consultation':
        return ChamberStatus.inConsultation;
      case 'consultation_ended':
        return ChamberStatus.consultationEnded;
      case 'shift_ended':
        return ChamberStatus.shiftEnded;
      case 'idle':
      default:
        return ChamberStatus.idle;
    }
  }

  String get wireName {
    switch (this) {
      case ChamberStatus.readyForNext:
        return 'ready_for_next';
      case ChamberStatus.calling:
        return 'calling';
      case ChamberStatus.inConsultation:
        return 'in_consultation';
      case ChamberStatus.consultationEnded:
        return 'consultation_ended';
      case ChamberStatus.shiftEnded:
        return 'shift_ended';
      case ChamberStatus.idle:
        return 'idle';
    }
  }
}

/// Strongly typed domain model representing the real-time chamber handshake session
/// between Reception and consulting Doctors.
///
/// Pure Dart model, zero Flutter UI or Firebase SDK dependencies.
class ChamberSession {
  final String doctorId;
  final DateTime date;
  final String status;
  final String? activeAppointmentId;
  final int? activeQueueNumber;
  final String? patientName;
  final String? patientPhone;
  final int? lastCompletedQueueNumber;
  final String? lastCompletedPatientName;

  ChamberStatus get statusEnum => ChamberStatus.fromString(status);

  const ChamberSession({
    required this.doctorId,
    required this.date,
    required this.status,
    this.activeAppointmentId,
    this.activeQueueNumber,
    this.patientName,
    this.patientPhone,
    this.lastCompletedQueueNumber,
    this.lastCompletedPatientName,
  });

  /// Factory creating an empty/idle chamber session.
  factory ChamberSession.empty(String doctorId, DateTime date) {
    return ChamberSession(
      doctorId: doctorId,
      date: date,
      status: 'idle',
      activeAppointmentId: null,
      activeQueueNumber: null,
      patientName: null,
      patientPhone: null,
      lastCompletedQueueNumber: null,
      lastCompletedPatientName: null,
    );
  }

  /// Deserializes a chamber session document payload from Firestore map.
  factory ChamberSession.fromMap(
    Map<String, dynamic>? data, {
    required String doctorId,
    required DateTime date,
  }) {
    if (data == null || data.isEmpty) {
      return ChamberSession.empty(doctorId, date);
    }

    return ChamberSession(
      doctorId: (data['doctorId'] as String?) ?? doctorId,
      date: date,
      status: (data['status'] as String?) ?? 'idle',
      activeAppointmentId: data['activeAppointmentId'] as String?,
      activeQueueNumber: (data['activeQueueNumber'] as num?)?.toInt(),
      patientName: data['patientName'] as String?,
      patientPhone: data['patientPhone'] as String?,
      lastCompletedQueueNumber: (data['lastCompletedQueueNumber'] as num?)
          ?.toInt(),
      lastCompletedPatientName: data['lastCompletedPatientName'] as String?,
    );
  }

  // Typed status indicator getters
  bool get isReadyForNext => status == 'ready_for_next';

  bool get isConsultationEnded => status == 'consultation_ended';

  bool get isCalling => status == 'calling';

  bool get isInConsultation => status == 'in_consultation';

  bool get isIdle => status == 'idle' || status.isEmpty;

  bool get isShiftEnded => status == 'shift_ended';

  /// True if a patient is currently active (calling or in consultation).
  bool get hasActivePatient =>
      (isCalling || isInConsultation) &&
      activeAppointmentId != null &&
      activeAppointmentId!.isNotEmpty;
}
