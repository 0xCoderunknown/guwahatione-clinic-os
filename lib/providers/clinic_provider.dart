import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/consultation.dart';
import '../models/medicine.dart';
import '../models/prescription_item.dart';
import '../models/user_role.dart';
import '../models/patient_review_eligibility.dart';
import '../services/firebase_service.dart';
import '../utils/app_constants.dart';

class ClinicProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  StreamSubscription? _appointmentSub;
  StreamSubscription? _doctorSub;
  StreamSubscription? _medicineSub;

  List<Doctor> _doctors = [];
  List<Appointment> _todayAppointments = [];
  List<Medicine> _medicines = [];
  bool _isLoading = false;

  List<Doctor> get doctors => _doctors;
  List<Appointment> get todayAppointments => _todayAppointments;
  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;

  int get pendingCount =>
      _todayAppointments.where((a) => a.status == AppointmentStatus.pending).length;

  int get dailyRevenue => _todayAppointments
      .where((a) => a.status == AppointmentStatus.completed)
      .fold(0, (sum, item) => sum + item.amountCollected);

  ClinicProvider() {
    _subscribeToDoctors();
    _subscribeToMedicines();
  }

  void startListeningToAppointments([DateTime? specificDate]) {
    final targetDate = specificDate ?? DateTime.now();
    _appointmentSub?.cancel();
    _appointmentSub = _firebaseService
        .getAppointmentsForDate(targetDate)
        .listen((appointments) {
          _todayAppointments = appointments;
          notifyListeners();
        });
  }

  void _subscribeToDoctors() {
    _doctorSub?.cancel();
    _doctorSub = _firebaseService.getDoctors().listen((doctors) {
      _doctors = doctors;
      notifyListeners();
    });
  }

  void _subscribeToMedicines() {
    _medicineSub?.cancel();
    _medicineSub = _firebaseService.getMedicines().listen((meds) {
      _medicines = meds;
      notifyListeners();
    });
  }

  Future<void> addDoctor(
    String name,
    String specialty,
    String phone,
    List<String> days, {
    String pin = '1234',
    int consultationFee = 500,
  }) async {
    _setLoading(true);
    try {
      final newDoctor = Doctor(
        id: _uuid.v4(),
        name: name,
        specialty: specialty,
        phone: phone,
        availableDays: days,
        blockedDates: [],
        pin: pin,
        consultationFee: consultationFee,
      );
      await _firebaseService.addDoctor(newDoctor);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }


  Future<Patient?> searchPatient(String phoneNumber) async {
    _setLoading(true);
    try {
      return await _firebaseService.getPatient(phoneNumber);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches appointment history for a given patient.
  Future<List<Appointment>> getAppointmentsForPatient(String phoneNumber) async {
    return await _firebaseService.getAppointmentsForPatient(phoneNumber);
  }

  /// Evaluates free review eligibility for a patient with a specific doctor.
  PatientReviewEligibility checkReviewEligibility({
    required List<Appointment> patientAppointments,
    required String? doctorId,
    required DateTime scheduledDate,
    String? doctorName,
  }) {
    return PatientReviewEligibility.calculate(
      appointments: patientAppointments,
      doctorId: doctorId,
      targetDate: scheduledDate,
      doctorName: doctorName,
    );
  }

  /// Returns [PaymentType.freeReview] if the patient visited the same doctor within 14 days,
  /// otherwise [PaymentType.paid].
  PaymentType calculatePaymentType({
    required List<Appointment> patientAppointments,
    required String? doctorId,
    required DateTime scheduledDate,
  }) {
    final eligibility = PatientReviewEligibility.calculate(
      appointments: patientAppointments,
      doctorId: doctorId,
      targetDate: scheduledDate,
    );
    if (eligibility.hasVisitedDoctorEarlier && eligibility.isWithin14Days) {
      return PaymentType.freeReview;
    }
    return PaymentType.paid;
  }

  Future<void> bookAppointment({
    required String phoneNumber,
    required String name,
    required int age,
    String gender = 'Male',
    required PaymentType paymentType,
    required int amountCollected,
    required DateTime scheduledDate,
    required Doctor selectedDoctor,
    bool isNewPatient = false,
  }) async {
    _setLoading(true);
    try {
      if (AppConstants.isDateBlocked(scheduledDate)) {
        throw Exception('Selected date is a clinic holiday.');
      }

      final hasDuplicate = await _firebaseService.hasAppointmentForDate(
        phoneNumber,
        scheduledDate,
      );
      if (hasDuplicate) {
        throw Exception('Patient already has an appointment on this date.');
      }

      // Enforce: Only a patient who visited earlier with the same doctor can get a free review.
      if (paymentType == PaymentType.freeReview) {
        final patientAppts =
            await _firebaseService.getAppointmentsForPatient(phoneNumber);
        final eligibility = PatientReviewEligibility.calculate(
          appointments: patientAppts,
          doctorId: selectedDoctor.id,
          targetDate: scheduledDate,
          doctorName: selectedDoctor.name,
        );
        if (!eligibility.hasVisitedDoctorEarlier) {
          throw Exception(
            'Free Review is only allowed for patients who previously visited Dr. ${selectedDoctor.name}.',
          );
        }
      }

      final patient = Patient(
        id: phoneNumber,
        name: name,
        age: age,
        gender: gender,
        lastVisitDate: DateTime.now(),
        phoneNumber: phoneNumber,
      );
      await _firebaseService.addPatient(patient);

      final queueNum = await _firebaseService.getNextQueueNumber(scheduledDate);

      final appointment = Appointment(
        id: _uuid.v4(),
        patientPhone: phoneNumber,
        patientName: name,
        status: AppointmentStatus.pending,
        paymentType: paymentType,
        amountCollected: amountCollected,
        queueNumber: queueNum,
        scheduledDate: scheduledDate,
        doctorId: selectedDoctor.id,
        doctorName: selectedDoctor.name,
      );

      await _firebaseService.createAppointment(appointment);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAppointmentStatus(
    String id,
    String status,
    String paymentType,
    int amount,
  ) async {
    try {
      final pType = PaymentType.values.firstWhere(
        (e) => e.name == paymentType,
        orElse: () => PaymentType.paid,
      );

      final statusEnum = AppointmentStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => AppointmentStatus.pending,
      );

      await _firebaseService.updateAppointmentStatus(
        id,
        statusEnum,
        collectedAmount: amount,
        paymentType: pType,
      );
    } catch (e) {
      debugPrint('Error updating status: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Longitudinal Consultations
  // ---------------------------------------------------------------------------

  Future<void> saveConsultation(Consultation consultation) async {
    _setLoading(true);
    try {
      await _firebaseService.saveConsultation(consultation);
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Consultation>> getPatientConsultations(String phone) async {
    return await _firebaseService.getConsultationsForPatient(phone);
  }

  Future<List<PrescriptionItem>> getActiveMedicationsForPatient(String phone) async {
    return await _firebaseService.getLatestActiveMedications(phone);
  }

  // ---------------------------------------------------------------------------
  // Master Medicine Catalogue
  // ---------------------------------------------------------------------------

  Future<void> addMedicine({
    required String productName,
    required String composition,
    required String strength,
    required String form,
    String? manufacturer,
    String? category,
    UserRole? requestingRole,
  }) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can modify the master medicine catalogue.',
      );
    }
    _setLoading(true);
    try {
      final med = Medicine(
        id: _uuid.v4(),
        productName: productName,
        composition: composition,
        strength: strength,
        form: form,
        manufacturer: manufacturer,
        category: category,
      );
      await _firebaseService.addMedicine(med);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMedicine(String medicineId, {UserRole? requestingRole}) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can modify the master medicine catalogue.',
      );
    }
    _setLoading(true);
    try {
      await _firebaseService.deleteMedicine(medicineId);
    } finally {
      _setLoading(false);
    }
  }

  Future<int> deduplicateMedicines({UserRole? requestingRole}) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can modify the master medicine catalogue.',
      );
    }
    _setLoading(true);
    try {
      return await _firebaseService.deduplicateMedicines();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> ensureDefaultMedicinesExist({UserRole? requestingRole}) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can modify the master medicine catalogue.',
      );
    }
    _setLoading(true);
    try {
      await _firebaseService.ensureDefaultMedicinesExist();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Medicine>> searchMedicines(String query) async {
    return await _firebaseService.searchMedicines(query);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _appointmentSub?.cancel();
    _doctorSub?.cancel();
    _medicineSub?.cancel();
    super.dispose();
  }
}
