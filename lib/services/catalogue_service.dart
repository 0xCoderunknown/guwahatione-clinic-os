import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine.dart';
import '../utils/default_medicines.dart';
import 'firestore_paths.dart';

/// Service managing the master clinic medicine catalogue, default seeds, and deduplication.
class CatalogueService {
  final FirebaseFirestore _firestore;

  CatalogueService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _medicinesRef =>
      _firestore.collection(FirestorePaths.medicines);

  Future<void> addMedicine(Medicine medicine) async {
    await _medicinesRef.doc(medicine.id).set(medicine.toJson());
  }

  Future<void> deleteMedicine(String medicineId) async {
    await _medicinesRef.doc(medicineId).delete();
  }

  Stream<List<Medicine>> getMedicines() {
    return _medicinesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Medicine.fromJson(doc.data())).toList();
    });
  }

  /// Ensures standard, essential OPD medicines exist in Firestore by default.
  /// Uses deterministic document IDs so execution is strictly idempotent.
  Future<void> ensureDefaultMedicinesExist() async {
    final snapshot = await _medicinesRef.limit(1).get();
    if (snapshot.docs.isEmpty) {
      final batch = _firestore.batch();
      for (final med in defaultEssentialMedicines) {
        batch.set(_medicinesRef.doc(med.id), med.toJson());
      }
      await batch.commit();
    }
  }

  /// Scans master catalogue, identifies duplicate entries (same name, composition, strength),
  /// preserves one canonical record, and batch deletes duplicates.
  Future<int> deduplicateMedicines() async {
    final snapshot = await _medicinesRef.get();
    if (snapshot.docs.isEmpty) return 0;

    final seenKeys = <String, String>{};
    final toDeleteDocIds = <String>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final productName = (data['productName'] as String? ?? '')
          .trim()
          .toLowerCase();
      final composition = (data['composition'] as String? ?? '')
          .trim()
          .toLowerCase();
      final strength = (data['strength'] as String? ?? '').trim().toLowerCase();

      final key = '$productName|$composition|$strength';

      if (seenKeys.containsKey(key)) {
        toDeleteDocIds.add(doc.id);
      } else {
        seenKeys[key] = doc.id;
      }
    }

    if (toDeleteDocIds.isNotEmpty) {
      for (var i = 0; i < toDeleteDocIds.length; i += 450) {
        final batch = _firestore.batch();
        final chunk = toDeleteDocIds.skip(i).take(450);
        for (final id in chunk) {
          batch.delete(_medicinesRef.doc(id));
        }
        await batch.commit();
      }
    }

    return toDeleteDocIds.length;
  }

  /// Searches the medicine catalogue across composition and trade brand name.
  Future<List<Medicine>> searchMedicines(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final snapshot = await _medicinesRef.get();
    return snapshot.docs.map((doc) => Medicine.fromJson(doc.data())).where((
      med,
    ) {
      final tradeNameMatch = med.productName.toLowerCase().contains(cleanQuery);
      final compositionMatch = med.composition.toLowerCase().contains(
        cleanQuery,
      );
      return tradeNameMatch || compositionMatch;
    }).toList();
  }
}
