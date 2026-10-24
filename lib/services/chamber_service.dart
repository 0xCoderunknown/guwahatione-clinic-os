import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/clinic_config.dart';
import '../models/appointment.dart';
import '../models/chamber_session.dart';
import 'firestore_paths.dart';

/// Service managing zero-touch real-time sync between Reception and Doctor Chamber screens.
class ChamberService {
  final FirebaseFirestore? _customFirestore;

  ChamberService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _countersRef =>
      _firestore.collection(FirestorePaths.counters);

  /// Broadcasts token calling event to doctor chamber screen.
  /// Atomically verifies and claims chamber occupancy inside a Firestore transaction.
  /// Strictly rejects if chamber is already occupied by another active patient.
  Future<void> callTokenIntoChamber({
    required String doctorId,
    required DateTime date,
    required Appointment appointment,
    bool forceOverride = false,
  }) async {
    final chamberDocId = FirestorePaths.chamberSyncDoc(doctorId, date);
    final docRef = _countersRef.doc(chamberDocId);

    await _firestore.runTransaction((transaction) async {
      if (!forceOverride) {
        if (ClinicConfig.current.features.enforceSingleActiveDoctor) {
          final dateKey = FirestorePaths.dateKey(date);
          final allChambersSnap = await _countersRef
              .where('date', isEqualTo: dateKey)
              .get();
          for (final doc in allChambersSnap.docs) {
            final data = doc.data();
            final otherDoctorId = data['doctorId'] as String?;
            final otherStatus = data['status'] as String?;
            final otherActiveId = data['activeAppointmentId'] as String?;
            if (otherDoctorId != null &&
                otherDoctorId != doctorId &&
                otherActiveId != null &&
                otherActiveId.isNotEmpty &&
                (otherStatus == 'calling' ||
                    otherStatus == 'in_consultation')) {
              throw StateError(
                'Single-Doctor Mode: Another doctor is currently consulting Token #${data['activeQueueNumber']} (${data['patientName'] ?? 'Patient'}). Only one doctor may consult at a time.',
              );
            }
          }
        }

        final snap = await transaction.get(docRef);
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

      transaction.set(docRef, {
        'doctorId': doctorId,
        'date': FirestorePaths.dateKey(date),
        'activeAppointmentId': appointment.id,
        'activeQueueNumber': appointment.queueNumber,
        'patientName': appointment.patientName,
        'patientPhone': appointment.patientPhone,
        'calledAt': FieldValue.serverTimestamp(),
        'status': 'calling',
      }, SetOptions(merge: true));
    });
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
    if (ClinicConfig.current.features.enforceSingleActiveDoctor) {
      final dateKey = FirestorePaths.dateKey(date);
      final allChambersSnap = await _countersRef
          .where('date', isEqualTo: dateKey)
          .get();
      for (final doc in allChambersSnap.docs) {
        final data = doc.data();
        final otherDoctorId = data['doctorId'] as String?;
        final otherStatus = data['status'] as String?;
        if (otherDoctorId != null &&
            otherDoctorId != doctorId &&
            (otherStatus == 'in_consultation' ||
                otherStatus == 'calling' ||
                otherStatus == 'ready_for_next')) {
          throw StateError(
            'Single-Doctor Mode: Another doctor is currently active in consultation. Only one doctor may consult at a time.',
          );
        }
      }
    }

    final chamberDocId = FirestorePaths.chamberSyncDoc(doctorId, date);
    await _countersRef.doc(chamberDocId).set({
      'doctorId': doctorId,
      'date': FirestorePaths.dateKey(date),
      'readyAt': FieldValue.serverTimestamp(),
      'status': 'ready_for_next',
    }, SetOptions(merge: true));
  }

  /// Broadcasts doctor shift ended / OPD concluded event to reception desk.
  /// Locks dispatch actions and clears active patient tokens from chamber channel.
  Future<void> notifyShiftEnded({
    required String doctorId,
    required DateTime date,
  }) async {
    final chamberDocId = FirestorePaths.chamberSyncDoc(doctorId, date);
    await _countersRef.doc(chamberDocId).set({
      'doctorId': doctorId,
      'date': FirestorePaths.dateKey(date),
      'activeAppointmentId': null,
      'activeQueueNumber': null,
      'status': 'shift_ended',
      'shiftEndedAt': FieldValue.serverTimestamp(),
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

  /// Broadcasts doctor arrival in clinic/chamber to reception desk.
  /// Sets status to 'in_chamber' if doc does not exist or status is currently 'idle'.
  Future<void> notifyDoctorArrived({
    required String doctorId,
    required DateTime date,
  }) async {
    final chamberDocId = FirestorePaths.chamberSyncDoc(doctorId, date);
    final docRef = _countersRef.doc(chamberDocId);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'doctorId': doctorId,
        'date': FirestorePaths.dateKey(date),
        'status': 'in_chamber',
        'arrivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      final currentStatus = snap.data()?['status'] as String?;
      if (currentStatus == null || currentStatus == 'idle') {
        await docRef.set({
          'status': 'in_chamber',
          'arrivedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
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

