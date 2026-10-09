/// Centralized Firestore collection and document path builders.
///
/// Single source of truth for all Firestore paths, eliminating path typos
/// and ensuring atomic counter consistency across doctor queues and chamber sync.
abstract class FirestorePaths {
  // Collection Names
  static const String patients = 'patients';
  static const String appointments = 'appointments';
  static const String counters = 'counters';
  static const String consultations = 'consultations';
  static const String medicines = 'medicines';
  static const String doctors = 'doctors';

  // Document Path Builders
  static String patientDoc(String phone) => phone;
  static String appointmentDoc(String id) => id;
  static String consultationDoc(String id) => id;
  static String medicineDoc(String id) => id;
  static String doctorDoc(String id) => id;

  /// Formats date into standard YYYY-MM-DD key.
  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Per-doctor, per-day atomic queue counter document ID:
  /// `counters/queue_{doctorId}_{yyyy-MM-dd}`
  static String doctorQueueCounter(String doctorId, DateTime date) =>
      'queue_${doctorId}_${dateKey(date)}';

  /// Per-doctor, per-day chamber sync document ID:
  /// `counters/chamber_{doctorId}_{yyyy-MM-dd}`
  static String chamberSyncDoc(String doctorId, DateTime date) =>
      'chamber_${doctorId}_${dateKey(date)}';
}
