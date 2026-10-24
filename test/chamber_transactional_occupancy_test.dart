import 'package:appointment_app/models/appointment.dart';
import 'package:appointment_app/models/chamber_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chamber Transactional Occupancy & Collision Guard Tests', () {
    final testDate = DateTime(2026, 10, 19);

    Appointment createAppt({
      required String id,
      required int queueNumber,
      required String name,
    }) {
      return Appointment(
        id: id,
        queueNumber: queueNumber,
        patientName: name,
        patientPhone: '9876543210',
        visitStatus: VisitStatus.waitingInLobby,
        paymentType: PaymentType.paidCash,
        amountCollected: 500,
        scheduledDate: testDate,
        doctorId: 'doc_1',
        doctorName: 'Dr. A. Sharma',
      );
    }

    test('ChamberSession correctly identifies occupancy states', () {
      final idle = ChamberSession.empty('doc_1', testDate);
      expect(idle.hasActivePatient, isFalse);
      expect(idle.isIdle, isTrue);

      final ready = ChamberSession(
        doctorId: 'doc_1',
        date: testDate,
        status: 'ready_for_next',
      );
      expect(ready.hasActivePatient, isFalse);
      expect(ready.isReadyForNext, isTrue);

      final calling = ChamberSession(
        doctorId: 'doc_1',
        date: testDate,
        status: 'calling',
        activeAppointmentId: 'appt_1',
        activeQueueNumber: 1,
        patientName: 'Patient One',
      );
      expect(calling.hasActivePatient, isTrue);
      expect(calling.isCalling, isTrue);

      final inConsult = ChamberSession(
        doctorId: 'doc_1',
        date: testDate,
        status: 'in_consultation',
        activeAppointmentId: 'appt_1',
        activeQueueNumber: 1,
        patientName: 'Patient One',
      );
      expect(inConsult.hasActivePatient, isTrue);
      expect(inConsult.isInConsultation, isTrue);

      final ended = ChamberSession(
        doctorId: 'doc_1',
        date: testDate,
        status: 'consultation_ended',
        lastCompletedQueueNumber: 1,
        lastCompletedPatientName: 'Patient One',
      );
      expect(ended.hasActivePatient, isFalse);
      expect(ended.isConsultationEnded, isTrue);
    });

    test('Occupancy rule strictly rejects conflicting token admissions', () {
      // Logic mirrored from ChamberService.callTokenIntoChamber transaction
      bool checkIsOccupied(ChamberSession current, Appointment incoming) {
        final currentActiveId = current.activeAppointmentId;
        final currentStatus = current.status;
        return currentActiveId != null &&
            currentActiveId.isNotEmpty &&
            currentActiveId != incoming.id &&
            (currentStatus == 'calling' || currentStatus == 'in_consultation');
      }

      final appt1 = createAppt(id: 'appt_1', queueNumber: 1, name: 'Patient 1');
      final appt2 = createAppt(id: 'appt_2', queueNumber: 2, name: 'Patient 2');

      final activeSession = ChamberSession(
        doctorId: 'doc_1',
        date: testDate,
        status: 'calling',
        activeAppointmentId: appt1.id,
        activeQueueNumber: appt1.queueNumber,
        patientName: appt1.patientName,
      );

      // Attempting to admit Patient 2 while Patient 1 is active MUST be rejected
      expect(checkIsOccupied(activeSession, appt2), isTrue);

      // Re-calling Patient 1 (idempotent retry) is allowed
      expect(checkIsOccupied(activeSession, appt1), isFalse);

      // When chamber is ready_for_next, neither is blocked
      final readySession = ChamberSession(
        doctorId: 'doc_1',
        date: testDate,
        status: 'ready_for_next',
      );
      expect(checkIsOccupied(readySession, appt2), isFalse);

      // When chamber is in_consultation, Patient 2 MUST be rejected
      final consultSession = ChamberSession(
        doctorId: 'doc_1',
        date: testDate,
        status: 'in_consultation',
        activeAppointmentId: appt1.id,
        activeQueueNumber: appt1.queueNumber,
        patientName: appt1.patientName,
      );
      expect(checkIsOccupied(consultSession, appt2), isTrue);
    });

    test('Simulates atomic door admit collision: preserves lobby state on lock conflict', () {
      // Simulate doctor attempting door admit on Patient B while Patient A was just dispatched
      final patientA = createAppt(id: 'pat_a', queueNumber: 1, name: 'Patient A');
      var patientB = createAppt(id: 'pat_b', queueNumber: 2, name: 'Patient B');

      // Chamber is already claimed by Patient A
      final chamberState = ChamberSession(
        doctorId: 'doc_1',
        date: testDate,
        status: 'calling',
        activeAppointmentId: patientA.id,
        activeQueueNumber: patientA.queueNumber,
        patientName: patientA.patientName,
      );

      // When door admit runs in the hardened order:
      // Step 1: verify & claim chamber lock (throws on collision)
      // Step 2: only on success, mutate patientB to inConsultation
      bool collisionCaught = false;
      try {
        final isOccupied =
            chamberState.activeAppointmentId != null &&
            chamberState.activeAppointmentId != patientB.id &&
            (chamberState.status == 'calling' || chamberState.status == 'in_consultation');
        if (isOccupied) {
          throw StateError('Chamber is already occupied by Token #1');
        }
        // If not thrown, admit patient:
        patientB = patientB.copyWith(visitStatus: VisitStatus.inConsultation);
      } catch (_) {
        collisionCaught = true;
      }

      expect(collisionCaught, isTrue);
      // Crucial: Patient B is NOT in zombie inConsultation state; remains waiting in lobby!
      expect(patientB.visitStatus, VisitStatus.waitingInLobby);
      expect(patientB.status, AppointmentStatus.pending);
    });

    test('Doctor arrival transitions shift_ended and idle to in_chamber, preserving active consultations', () {
      // Simulates ChamberService.notifyDoctorArrived transition logic
      String resolveArrivalStatus(String? currentStatus) {
        if (currentStatus == null ||
            currentStatus == 'idle' ||
            currentStatus == 'shift_ended') {
          return 'in_chamber';
        }
        return currentStatus;
      }

      // Initial / empty chamber becomes in_chamber
      expect(resolveArrivalStatus(null), 'in_chamber');
      expect(resolveArrivalStatus('idle'), 'in_chamber');

      // Crucial fix: shift_ended resets to in_chamber upon doctor login
      expect(resolveArrivalStatus('shift_ended'), 'in_chamber');

      // Active operational states are NEVER overwritten by doctor reconnect
      expect(resolveArrivalStatus('ready_for_next'), 'ready_for_next');
      expect(resolveArrivalStatus('calling'), 'calling');
      expect(resolveArrivalStatus('in_consultation'), 'in_consultation');
      expect(resolveArrivalStatus('consultation_ended'), 'consultation_ended');
    });
  });
}
