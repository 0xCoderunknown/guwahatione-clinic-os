import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/medicine.dart';
import '../../models/user_role.dart';
import '../../services/catalogue_service.dart';

/// Delegate controller responsible for formulary catalogue streams,
/// custom medicine additions, deletions, deduplications, and searches.
class CatalogueDelegate {
  final CatalogueService _catalogueService;
  final Uuid _uuid;
  final VoidCallback _notifyListeners;

  StreamSubscription? _medicineSub;
  List<Medicine> _medicines = [];

  CatalogueDelegate({
    CatalogueService? catalogueService,
    Uuid? uuid,
    required this._notifyListeners,
  }) : _catalogueService = catalogueService ?? CatalogueService(),
       _uuid = uuid ?? const Uuid() {
    subscribeToMedicines();
  }

  List<Medicine> get medicines => _medicines;

  void subscribeToMedicines() {
    _medicineSub?.cancel();
    _medicineSub = _catalogueService.getMedicines().listen((meds) {
      _medicines = meds;
      _notifyListeners();
    });
  }

  Future<void> addMedicine({
    required String productName,
    required String composition,
    String? manufacturer,
    String? defaultDosage,
    String? defaultFrequency,
    String? defaultTiming,
    int? defaultDurationDays,
    String? defaultDuration,
    UserRole? requestingRole,
  }) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can modify the master medicine catalogue.',
      );
    }
    final med = Medicine(
      id: _uuid.v4(),
      productName: productName,
      composition: composition,
      manufacturer: manufacturer,
      defaultDosage: defaultDosage,
      defaultFrequency: defaultFrequency,
      defaultTiming: defaultTiming,
      defaultDurationDays: defaultDurationDays,
      defaultDuration: defaultDuration,
    );
    await _catalogueService.addMedicine(med);
  }

  Future<void> deleteMedicine(
    String medicineId, {
    UserRole? requestingRole,
  }) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can modify the master medicine catalogue.',
      );
    }
    await _catalogueService.deleteMedicine(medicineId);
  }

  Future<int> deduplicateMedicines({UserRole? requestingRole}) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can modify the master medicine catalogue.',
      );
    }
    return await _catalogueService.deduplicateMedicines();
  }

  Future<void> ensureDefaultMedicinesExist({UserRole? requestingRole}) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can modify the master medicine catalogue.',
      );
    }
    await _catalogueService.ensureDefaultMedicinesExist();
  }

  Future<List<Medicine>> searchMedicines(String query) async {
    return await _catalogueService.searchMedicines(query);
  }

  void dispose() {
    _medicineSub?.cancel();
  }
}
