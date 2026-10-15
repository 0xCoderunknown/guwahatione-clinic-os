import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient.dart';
import 'firestore_paths.dart';

/// Service managing patient demographics lookup and retrieval.
class PatientService {
  final FirebaseFirestore _firestore;

  PatientService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _firestore.collection(FirestorePaths.patients);

  /// Retrieves a patient demographic profile by primary key (patient ID or legacy phone).
  Future<Patient?> getPatient(String idOrPhone) async {
    final clean = idOrPhone.trim();
    if (clean.isEmpty) return null;

    // 1. Direct ID document lookup
    final doc = await _patientsRef.doc(clean).get();
    if (doc.exists && doc.data() != null) {
      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] ??= doc.id;
      data['phoneNumber'] ??= doc.id;
      return Patient.fromJson(data);
    }

    // 2. Fallback query by phoneNumber index for legacy records or phone queries
    final querySnap = await _patientsRef
        .where('phoneNumber', isEqualTo: clean)
        .limit(1)
        .get();

    if (querySnap.docs.isNotEmpty) {
      final qDoc = querySnap.docs.first;
      final data = Map<String, dynamic>.from(qDoc.data());
      data['id'] ??= qDoc.id;
      return Patient.fromJson(data);
    }

    return null;
  }

  /// Retrieves all patient profiles associated with a shared contact phone number (household members).
  Future<List<Patient>> getPatientsForPhone(String phoneNumber) async {
    final clean = phoneNumber.trim();
    if (clean.isEmpty) return [];

    final results = <String, Patient>{};

    // 1. Query all patients whose contact phone matches
    final snap = await _patientsRef
        .where('phoneNumber', isEqualTo: clean)
        .get();

    for (final doc in snap.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] ??= doc.id;
      results[doc.id] = Patient.fromJson(data);
    }

    // 2. Check legacy direct phone-keyed document if not already picked up
    if (!results.containsKey(clean)) {
      final legacyDoc = await _patientsRef.doc(clean).get();
      if (legacyDoc.exists && legacyDoc.data() != null) {
        final data = Map<String, dynamic>.from(legacyDoc.data()!);
        data['id'] ??= legacyDoc.id;
        data['phoneNumber'] ??= legacyDoc.id;
        results[legacyDoc.id] = Patient.fromJson(data);
      }
    }

    return results.values.toList();
  }

  /// Persists or updates a patient record keyed by unique patient.id.
  Future<void> savePatient(Patient patient) async {
    await _patientsRef
        .doc(patient.id)
        .set(patient.toJson(), SetOptions(merge: true));
  }

  /// Searches patients by phone number (exact or prefix) or by name.
  /// Strictly zero Firestore queries when query is empty.
  Future<List<Patient>> searchPatients(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    final isNumeric = RegExp(r'^\d+$').hasMatch(clean);

    if (isNumeric) {
      final results = <String, Patient>{};

      // 1. Direct phone document lookup (legacy)
      final directDoc = await _patientsRef.doc(clean).get();
      if (directDoc.exists && directDoc.data() != null) {
        final data = Map<String, dynamic>.from(directDoc.data()!);
        data['id'] ??= directDoc.id;
        data['phoneNumber'] ??= directDoc.id;
        results[directDoc.id] = Patient.fromJson(data);
      }

      // 2. Query by phoneNumber field (household index)
      final phoneSnap = await _patientsRef
          .where('phoneNumber', isEqualTo: clean)
          .limit(10)
          .get();
      for (final doc in phoneSnap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] ??= doc.id;
        results[doc.id] = Patient.fromJson(data);
      }

      // 3. Prefix query if 3+ digits on documentId
      if (clean.length >= 3) {
        final prefixSnap = await _patientsRef
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: clean)
            .where(FieldPath.documentId, isLessThanOrEqualTo: '$clean\uf8ff')
            .limit(15)
            .get();

        for (final doc in prefixSnap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] ??= doc.id;
          data['phoneNumber'] ??= doc.id;
          results[doc.id] = Patient.fromJson(data);
        }
      }

      return results.values.toList();
    } else {
      // Name prefix search (case-normalized)
      final capitalized = clean.isNotEmpty
          ? '${clean[0].toUpperCase()}${clean.substring(1)}'
          : clean;

      final results = <String, Patient>{};

      final snap1 = await _patientsRef
          .where('name', isGreaterThanOrEqualTo: clean)
          .where('name', isLessThanOrEqualTo: '$clean\uf8ff')
          .limit(15)
          .get();

      for (final doc in snap1.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] ??= doc.id;
        data['phoneNumber'] ??= doc.id;
        results[doc.id] = Patient.fromJson(data);
      }

      if (capitalized != clean) {
        final snap2 = await _patientsRef
            .where('name', isGreaterThanOrEqualTo: capitalized)
            .where('name', isLessThanOrEqualTo: '$capitalized\uf8ff')
            .limit(15)
            .get();

        for (final doc in snap2.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] ??= doc.id;
          data['phoneNumber'] ??= doc.id;
          results[doc.id] = Patient.fromJson(data);
        }
      }

      return results.values.toList();
    }
  }
}
