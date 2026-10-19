import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment.dart';
import '../models/chamber_session.dart';
import 'firestore_paths.dart';

/// Service managing zero-touch real-time sync between Reception and Doctor Chamber screens.
class ChamberService {
  final FirebaseFirestore _firestore;

  ChamberService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _countersRef =>
      _firestore.collection(FirestorePaths.counters);

  /// Broadcasts token calling event to doctor chamber screen.
  /// Strictly rejects if chamber is already occupied by another active patient.
  Future<void> callTokenIntoChamber({
    required String doctorId,
    required DateTime date,
    required Appointment appointment,
    bool forceOverride = false,
  }) async {
    final chamberDocId = FirestorePaths.chamberSyncDoc(doctorId, date);
    final docRef = _countersRef.doc(chamberDocId);

    if (!forceOverride) {
      final snap = await docRef.get();
      if (snap.exists) {
        final currentData = snap.data();
        final currentActiveId = currentData?['activeAppointmentId'] as String?;
        final currentStatus = currentData?['status'] as String?;
        final isOccupied =
            currentActiveId != null &&
            currentActiveId.isNotEmpty &&
            currentActiveId != appointment.id &&
            (currentStatus == 'calling' || currentStatus == 'in_consultation');
        if (isOccupied) {
          throw StateError(
            'Chamber is already occupied by Token #${currentData?['activeQueueNumber']} (${currentData?['patientName']}). Conclude active consultation before admitting next patient.',
          );
        }
      }
    }

    await docRef.set({
      'doctorId': doctorId,
      'date': FirestorePaths.dateKey(date),
      'activeAppointmentId': appointment.id,
      'activeQueueNumber': appointment.queueNumber,
      'patientName': appointment.patientName,
      'patientPhone': appointment.patientPhone,
      'calledAt': FieldValue.serverTimestamp(),
      'status': 'calling',
    }, SetOptions(merge: true));
  }

  /// Streams active chamber session for a given doctor and date as a strongly typed domain model.
  Stream<ChamberSession> streamChamberSession(String doctorId, DateTime date) {
    final chamberDocId = FirestorePaths.chamberSyncDoc(doctorId, date);
    return _countersRef.doc(chamberDocId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return ChamberSession.empty(doctorId, date);
      }
      return ChamberSession.fromMap(
        snapshot.data(),
        doctorId: doctorId,
        date: date,
      );
    });
  }

  /// Streams active chamber sessions across all doctors for a given date in real-time.
  Stream<Map<String, ChamberSession>> streamAllChamberSessions(DateTime date) {
    return _countersRef
        .where('date', isEqualTo: FirestorePaths.dateKey(date))
        .snapshots()
        .map((snapshot) {
          final map = <String, ChamberSession>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final docId = data['doctorId'] as String?;
            if (docId != null && docId.isNotEmpty) {
              map[docId] = ChamberSession.fromMap(
                data,
                doctorId: docId,
                date: date,
              );
            }
          }
          return map;
        });
  }

  /// Broadcasts consultation ended event from doctor to reception desk.
  Future<void> notifyConsultationEnded({
    required String doctorId,
    required DateTime date,
    required int queueNumber,
    required String patientName,
  }) async {
    final chamberDocId = FirestorePaths.chamberSyncDoc(doctorId, date);
    await _countersRef.doc(chamberDocId).set({
      'doctorId': doctorId,
      'date': FirestorePaths.dateKey(date),
      'activeAppointmentId': null,
      'activeQueueNumber': null,
      'lastCompletedQueueNumber': queueNumber,
      'lastCompletedPatientName': patientName,
      'endedAt': FieldValue.serverTimestamp(),
      'status': 'consultation_ended',
    }, SetOptions(merge: true));
  }

  /// Broadcasts doctor's readiness for next patient to reception desk.
  Future<void> notifyReadyForNext({
    required String doctorId,
    required DateTime date,
  }) async {
    final chamberDocId = FirestorePaths.chamberSyncDoc(doctorId, date);
    await _countersRef.doc(chamberDocId).set({
      'doctorId': doctorId,
      'date': FirestorePaths.dateKey(date),
      'readyAt': FieldValue.serverTimestamp(),
      'status': 'ready_for_next',
    }, SetOptions(merge: true));
  }

  /// Broadcasts consultation paused event from doctor to reception desk.
  /// Frees active chamber so doctor can take next patient or reception can dispatch.
  Future<void> notifyConsultationPaused({
    required String doctorId,
    required DateTime date,
  }) async {
    final chamberDocId = FirestorePaths.chamberSyncDoc(doctorId, date);
    await _countersRef.doc(chamberDocId).set({
      'doctorId': doctorId,
      'date': FirestorePaths.dateKey(date),
      'activeAppointmentId': null,
      'activeQueueNumber': null,
      'status': 'ready_for_next',
      'pausedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Broadcasts that doctor has opened/started consultation encounter with the admitted patient.
  Future<void> notifyConsultationStarted({
    required String doctorId,
    required DateTime date,
    required Appointment appointment,
  }) async {
    final chamberDocId = FirestorePaths.chamberSyncDoc(doctorId, date);
    await _countersRef.doc(chamberDocId).set({
      'doctorId': doctorId,
      'date': FirestorePaths.dateKey(date),
      'activeAppointmentId': appointment.id,
      'activeQueueNumber': appointment.queueNumber,
      'patientName': appointment.patientName,
      'patientPhone': appointment.patientPhone,
      'status': 'in_consultation',
    }, SetOptions(merge: true));
  }

  /// Clears active chamber session, returning queue display to idle.
  Future<void> clearChamberSession(String doctorId, DateTime date) async {
    final chamberDocId = FirestorePaths.chamberSyncDoc(doctorId, date);
    await _countersRef.doc(chamberDocId).set({
      'activeAppointmentId': null,
      'activeQueueNumber': null,
      'status': 'idle',
      'clearedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
