import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firestore_paths.dart';

/// Service managing remote synchronization of clinic access PIN hashes.
///
/// Persists salted SHA-256 hashes to `clinic_config/security` enabling real-time
/// multi-terminal synchronization across Reception PCs, Doctor Chambers, and Owner sessions.
class SecurityService {
  final FirebaseFirestore? _customFirestore;

  SecurityService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  /// Stream of security settings changes from Firestore.
  Stream<DocumentSnapshot<Map<String, dynamic>>> securityStream() {
    try {
      return _firestore
          .collection(FirestorePaths.clinicConfig)
          .doc(FirestorePaths.securityDoc)
          .snapshots();
    } catch (e) {
      debugPrint('SecurityService: error subscribing to security settings stream: $e');
      return const Stream.empty();
    }
  }

  /// Updates salted SHA-256 PIN hashes in Firestore with merge semantics.
  Future<void> updateSecurityPins({
    String? ownerMasterPinHash,
    String? receptionistPinHash,
  }) async {
    final Map<String, dynamic> data = {
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': 'owner',
    };
    if (ownerMasterPinHash != null) {
      data['ownerMasterPinHash'] = ownerMasterPinHash;
    }
    if (receptionistPinHash != null) {
      data['receptionistPinHash'] = receptionistPinHash;
    }

    await _firestore
        .collection(FirestorePaths.clinicConfig)
        .doc(FirestorePaths.securityDoc)
        .set(data, SetOptions(merge: true));
  }
}
