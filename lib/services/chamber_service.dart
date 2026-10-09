import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import 'firestore_paths.dart';

/// Service managing zero-touch real-time sync between Reception and Doctor Chamber screens.
class ChamberService {
  final FirebaseFirestore _firestore;

  ChamberService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _countersRef =>
      _firestore.collection(FirestorePaths.counters);

  /// Broadcasts token calling event to doctor chamber screen.
  Future<void> callTokenIntoChamber({
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
      'calledAt': FieldValue.serverTimestamp(),
      'status': 'calling',
    }, SetOptions(merge: true));
  }

  /// Streams active chamber session document for a given doctor and date.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamChamberSession(
    String doctorId,
    DateTime date,
  ) {
    final chamberDocId = FirestorePaths.chamberSyncDoc(doctorId, date);
    return _countersRef.doc(chamberDocId).snapshots();
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
