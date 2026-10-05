import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../services/firebase_service.dart';
import '../utils/app_constants.dart';

class ClinicProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  StreamSubscription? _appointmentSub;
  StreamSubscription? _doctorSub;

  List<Doctor> _doctors = [];
  List<Appointment> _todayAppointments = [];
  bool _isLoading = false;

  List<Doctor> get doctors => _doctors;
  List<Appointment> get todayAppointments => _todayAppointments;
  bool get isLoading => _isLoading;

  int get pendingCount =>
      _todayAppointments.where((a) => a.status == AppointmentStatus.pending).length;

  int get dailyRevenue => _todayAppointments
      .where((a) => a.status == AppointmentStatus.completed)
      .fold(0, (sum, item) => sum + item.amountCollected);

  ClinicProvider() {
    _subscribeToDoctors();
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

  /// Returns [PaymentType.freeReview] if the patient visited within 15 days,
  /// otherwise [PaymentType.paid].
  PaymentType calculatePaymentType(Patient? patient) {
    if (patient == null) return PaymentType.paid;
    final difference = DateTime.now().difference(patient.lastVisitDate).inDays;
    if (difference < 15) return PaymentType.freeReview;
    return PaymentType.paid;
  }

  Future<void> bookAppointment({
    required String phoneNumber,
    required String name,
    required int age,
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

      final patient = Patient(
        id: phoneNumber,
        name: name,
        age: age,
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
      PaymentType pType;
      try {
        pType = PaymentType.values.byName(paymentType);
      } catch (e) {
        pType = PaymentType.paid;
      }

      final statusEnum = AppointmentStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () {
          if (status == 'cancelled') return AppointmentStatus.absent;
          return AppointmentStatus.pending;
        },
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _appointmentSub?.cancel();
    _doctorSub?.cancel();
    super.dispose();
  }
}
