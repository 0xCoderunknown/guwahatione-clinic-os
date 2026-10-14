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

  /// Retrieves a patient demographic profile by primary key (phone number).
  Future<Patient?> getPatient(String phoneNumber) async {
    final doc = await _patientsRef.doc(phoneNumber).get();
    if (doc.exists && doc.data() != null) {
      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] ??= doc.id;
      data['phoneNumber'] ??= doc.id;
      return Patient.fromJson(data);
    }
    return null;
  }

  /// Searches patients by phone number (exact or prefix) or by name.
  /// Strictly zero Firestore queries when query is empty.
  Future<List<Patient>> searchPatients(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    final isNumeric = RegExp(r'^\d+$').hasMatch(clean);

    if (isNumeric) {
      final results = <String, Patient>{};

      // 1. Direct phone document lookup
      final directDoc = await _patientsRef.doc(clean).get();
      if (directDoc.exists && directDoc.data() != null) {
        final data = Map<String, dynamic>.from(directDoc.data()!);
        data['id'] ??= directDoc.id;
        data['phoneNumber'] ??= directDoc.id;
        results[directDoc.id] = Patient.fromJson(data);
      }

      // 2. Prefix query if 3+ digits
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
