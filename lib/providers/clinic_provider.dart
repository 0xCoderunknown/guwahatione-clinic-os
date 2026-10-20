import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/engines/engines.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'delegates/catalogue_delegate.dart';
import 'delegates/doctor_state_delegate.dart';
import 'delegates/live_queue_delegate.dart';

/// Central state coordinator for GuwahatiOne Clinic OS.
/// Functions as a lightweight, backward-compatible Facade over focused domain delegates:
/// - [DoctorStateDelegate]: Master doctor roster, schedules, and active statuses.
/// - [LiveQueueDelegate]: Live queue stream, offline cache, midnight rollover, and desk actions.
/// - [CatalogueDelegate]: Master medicine formulary streams, searches, and curation.
class ClinicProvider with ChangeNotifier {
  final ChamberService _chamberService;
  final ConsultationService _consultationService;
  final PatientService _patientService;

  late final DoctorStateDelegate _doctorDelegate;
  late final LiveQueueDelegate _queueDelegate;
  late final CatalogueDelegate _catalogueDelegate;

  bool _isLoading = false;

  ClinicProvider({
    BookingService? bookingService,
    DoctorService? doctorService,
    CatalogueService? catalogueService,
    ChamberService? chamberService,
    ConsultationService? consultationService,
    PatientService? patientService,
    Uuid? uuid,
    bool enableMidnightObserver = true,
  }) : _chamberService = chamberService ?? ChamberService(),
       _consultationService = consultationService ?? ConsultationService(),
       _patientService = patientService ?? PatientService() {
    final effectiveUuid = uuid ?? const Uuid();

    _doctorDelegate = DoctorStateDelegate(
      doctorService: doctorService,
      uuid: effectiveUuid,
      notifyListeners: notifyListeners,
    );

    _queueDelegate = LiveQueueDelegate(
      bookingService: bookingService,
      uuid: effectiveUuid,
      enableMidnightObserver: enableMidnightObserver,
      notifyListeners: notifyListeners,
    );

    _catalogueDelegate = CatalogueDelegate(
      catalogueService: catalogueService,
      uuid: effectiveUuid,
      notifyListeners: notifyListeners,
    );
  }

  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Doctor Master Roster & Profiles (Delegated)
  // ---------------------------------------------------------------------------

  List<Doctor> get doctors => _doctorDelegate.doctors;
  List<Doctor> get allDoctors => _doctorDelegate.allDoctors;
  List<Doctor> get inactiveDoctors => _doctorDelegate.inactiveDoctors;
  bool get hasLoadedDoctors => _doctorDelegate.hasLoadedDoctors;
  Doctor? getDoctorById(String doctorId) =>
      _doctorDelegate.getDoctorById(doctorId);

  Future<void> addDoctor(
    String name,
    String specialty,
    String phone,
    List<String> days, {
    List<DateTime> blockedDates = const [],
    String pin = '1234',
    int consultationFee = 500,
    int freeReviewDays = 14,
    String? medicalRegNumber,
    String shiftTiming = '6:00 PM – 8:30 PM',
    int dailyTokenLimit = 18,
    int doctorSharePercentage = 100,
    UserRole? requestingRole,
  }) async {
    _setLoading(true);
    try {
      await _doctorDelegate.addDoctor(
        name,
        specialty,
        phone,
        days,
        blockedDates: blockedDates,
        pin: pin,
        consultationFee: consultationFee,
        freeReviewDays: freeReviewDays,
        medicalRegNumber: medicalRegNumber,
        shiftTiming: shiftTiming,
        dailyTokenLimit: dailyTokenLimit,
        doctorSharePercentage: doctorSharePercentage,
        requestingRole: requestingRole,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDoctor(Doctor doctor, {UserRole? requestingRole}) async {
    _setLoading(true);
    try {
      await _doctorDelegate.updateDoctor(
        doctor,
        requestingRole: requestingRole,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDoctorLeave(
    String doctorId,
    List<DateTime> blockedDates, {
    UserRole? requestingRole,
  }) async {
    _setLoading(true);
    try {
      await _doctorDelegate.updateDoctorLeave(
        doctorId,
        blockedDates,
        requestingRole: requestingRole,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setDoctorActiveStatus(
    String doctorId,
    bool isActive, {
    UserRole? requestingRole,
  }) async {
    _setLoading(true);
    try {
      await _doctorDelegate.setDoctorActiveStatus(
        doctorId,
        isActive,
        requestingRole: requestingRole,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDoctorSearchPreference(
    String doctorId,
    String searchPreference,
  ) async {
    await _doctorDelegate.updateDoctorSearchPreference(
      doctorId,
      searchPreference,
    );
  }

  // ---------------------------------------------------------------------------
  // Live Queue & Appointments (Delegated)
  // ---------------------------------------------------------------------------

  List<Appointment> get todayAppointments => _queueDelegate.todayAppointments;
  bool get isOfflineFallback => _queueDelegate.isOfflineFallback;
  DateTime? get offlineCacheTimestamp => _queueDelegate.offlineCacheTimestamp;
  bool get isCustomDateSelected => _queueDelegate.isCustomDateSelected;
  DateTime? get activeListeningDate => _queueDelegate.activeListeningDate;
  String get dashboardSearchQuery => _queueDelegate.dashboardSearchQuery;

  int get pendingCount => _queueDelegate.pendingCount;
  int get waitingCount => _queueDelegate.waitingCount;
  int get waitingInLobbyCount => _queueDelegate.waitingInLobbyCount;
  int get expectedBookedCount => _queueDelegate.expectedBookedCount;
  int get inConsultationCount => _queueDelegate.inConsultationCount;
  int get completedCount => _queueDelegate.completedCount;
  int get absentCount => _queueDelegate.absentCount;
  int get lobbyWaitingCount => _queueDelegate.lobbyWaitingCount;
  int get bookedCount => _queueDelegate.bookedCount;
  int get dailyRevenue => _queueDelegate.dailyRevenue;

  void setDashboardSearchQuery(String query) =>
      _queueDelegate.setDashboardSearchQuery(query);

  void clearDashboardSearchQuery() =>
      _queueDelegate.clearDashboardSearchQuery();

  List<Appointment> getFilteredAppointments({String? doctorId}) =>
      _queueDelegate.getFilteredAppointments(doctorId: doctorId);

  void checkAndHandleMidnightRollover([DateTime? currentTime]) =>
      _queueDelegate.checkAndHandleMidnightRollover(currentTime);

  void startListeningToAppointments([DateTime? specificDate]) =>
      _queueDelegate.startListeningToAppointments(specificDate);

  Future<Appointment> bookAppointment({
    String? patientId,
    required String phoneNumber,
    required String name,
    required int age,
    int? ageMonths,
    int? ageDays,
    String? guardianName,
    String? guardianRelation,
    String gender = 'Male',
    VisitStatus visitStatus = VisitStatus.waitingInLobby,
    required PaymentType paymentType,
    required int amountCollected,
    required DateTime scheduledDate,
    required Doctor selectedDoctor,
    bool isNewPatient = false,
  }) async {
    _setLoading(true);
    try {
      return await _queueDelegate.bookAppointment(
        patientId: patientId,
        phoneNumber: phoneNumber,
        name: name,
        age: age,
        ageMonths: ageMonths,
        ageDays: ageDays,
        guardianName: guardianName,
        guardianRelation: guardianRelation,
        gender: gender,
        visitStatus: visitStatus,
        paymentType: paymentType,
        amountCollected: amountCollected,
        scheduledDate: scheduledDate,
        selectedDoctor: selectedDoctor,
        isNewPatient: isNewPatient,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkInPatient({
    required String appointmentId,
    required PaymentType paymentType,
    required int amountCollected,
  }) => _queueDelegate.checkInPatient(
    appointmentId: appointmentId,
    paymentType: paymentType,
    amountCollected: amountCollected,
  );

  Future<void> admitPatientToChamber(String appointmentId) =>
      _queueDelegate.admitPatientToChamber(appointmentId);

  Future<void> updateAppointmentStatus(
    String id,
    String status,
    String paymentType,
    int amount, {
    VisitStatus? visitStatus,
  }) => _queueDelegate.updateAppointmentStatus(
    id,
    status,
    paymentType,
    amount,
    visitStatus: visitStatus,
  );

  Future<void> markAppointmentAbsent(Appointment appointment) =>
      _queueDelegate.markAppointmentAbsent(appointment);

  Stream<List<Appointment>> streamUpcomingAppointments({int daysAhead = 7}) =>
      _queueDelegate.streamUpcomingAppointments(daysAhead: daysAhead);

  Future<List<Appointment>> getAppointmentsForPatient(
    String patientId, {
    String? phone,
  }) => _queueDelegate.getAppointmentsForPatient(patientId, phone: phone);

  Future<int> closeDoctorSession({
    required String doctorId,
    required DateTime date,
    UserRole? requestingRole,
    String reason = 'Doctor absent / session closed',
  }) async {
    _setLoading(true);
    try {
      return await _queueDelegate.closeDoctorSession(
        doctorId: doctorId,
        date: date,
        requestingRole: requestingRole,
        reason: reason,
      );
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Chamber Zero-Touch Real-Time Handshake
  // ---------------------------------------------------------------------------

  Future<void> callTokenIntoChamber({
    required String doctorId,
    required DateTime date,
    required Appointment appointment,
    bool forceOverride = false,
  }) async {
    try {
      await _chamberService.callTokenIntoChamber(
        doctorId: doctorId,
        date: date,
        appointment: appointment,
        forceOverride: forceOverride,
      );
      SoundService.instance.announceToken(
        tokenNumber: appointment.queueNumber,
        doctorName: appointment.doctorName,
        callKey: '${doctorId}_${appointment.id}',
      );
    } catch (e) {
      debugPrint('Error calling token into chamber: $e');
      rethrow;
    }
  }

  Stream<Map<String, ChamberSession>> streamAllChamberSessions(DateTime date) {
    return _chamberService.streamAllChamberSessions(date);
  }

  Future<void> notifyConsultationEnded({
    required String doctorId,
    required DateTime date,
    required int queueNumber,
    required String patientName,
  }) async {
    try {
      await _chamberService.notifyConsultationEnded(
        doctorId: doctorId,
        date: date,
        queueNumber: queueNumber,
        patientName: patientName,
      );
    } catch (e) {
      debugPrint('Error notifying consultation ended: $e');
    }
  }

  Future<void> notifyReadyForNext({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      await _chamberService.notifyReadyForNext(doctorId: doctorId, date: date);
    } catch (e) {
      debugPrint('Error notifying ready for next: $e');
      rethrow;
    }
  }

  Future<void> notifyShiftEnded({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      await _chamberService.notifyShiftEnded(doctorId: doctorId, date: date);
    } catch (e) {
      debugPrint('Error notifying shift ended: $e');
      rethrow;
    }
  }

  Future<void> notifyConsultationStarted({
    required String doctorId,
    required DateTime date,
    required Appointment appointment,
  }) async {
    try {
      await _chamberService.notifyConsultationStarted(
        doctorId: doctorId,
        date: date,
        appointment: appointment,
      );
      await _queueDelegate.admitPatientToChamber(appointment.id);
    } catch (e) {
      debugPrint('Error notifying consultation started: $e');
    }
  }

  Future<void> pauseConsultation({
    required String appointmentId,
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      await _queueDelegate.pauseAppointment(appointmentId);
      await _chamberService.notifyConsultationPaused(
        doctorId: doctorId,
        date: date,
      );
    } catch (e) {
      debugPrint('Error pausing consultation: $e');
      rethrow;
    }
  }

  Future<void> clearChamberSession(String doctorId, DateTime date) async {
    try {
      await _chamberService.clearChamberSession(doctorId, date);
    } catch (e) {
      debugPrint('Error clearing chamber session: $e');
    }
  }

  Stream<ChamberSession> streamChamberSession(String doctorId, DateTime date) {
    return _chamberService.streamChamberSession(doctorId, date);
  }

  // ---------------------------------------------------------------------------
  // Master Medicine Catalogue (Delegated)
  // ---------------------------------------------------------------------------

  List<Medicine> get medicines => _catalogueDelegate.medicines;

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
    _setLoading(true);
    try {
      await _catalogueDelegate.addMedicine(
        productName: productName,
        composition: composition,
        manufacturer: manufacturer,
        defaultDosage: defaultDosage,
        defaultFrequency: defaultFrequency,
        defaultTiming: defaultTiming,
        defaultDurationDays: defaultDurationDays,
        defaultDuration: defaultDuration,
        requestingRole: requestingRole,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMedicine(
    String medicineId, {
    UserRole? requestingRole,
  }) async {
    _setLoading(true);
    try {
      await _catalogueDelegate.deleteMedicine(
        medicineId,
        requestingRole: requestingRole,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<int> deduplicateMedicines({UserRole? requestingRole}) async {
    _setLoading(true);
    try {
      return await _catalogueDelegate.deduplicateMedicines(
        requestingRole: requestingRole,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> ensureDefaultMedicinesExist({UserRole? requestingRole}) async {
    _setLoading(true);
    try {
      await _catalogueDelegate.ensureDefaultMedicinesExist(
        requestingRole: requestingRole,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Medicine>> searchMedicines(String query) =>
      _catalogueDelegate.searchMedicines(query);

  // ---------------------------------------------------------------------------
  // Patient Directory Passthrough
  // ---------------------------------------------------------------------------

  Future<Patient?> searchPatient(String phoneNumber) async {
    _setLoading(true);
    try {
      return await _patientService.getPatient(phoneNumber);
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Patient>> getPatientsForPhone(String phoneNumber) =>
      _patientService.getPatientsForPhone(phoneNumber);

  Future<void> savePatient(Patient patient) =>
      _patientService.savePatient(patient);

  Future<List<Patient>> searchPatients(String query) =>
      _patientService.searchPatients(query);

  // ---------------------------------------------------------------------------
  // Longitudinal Consultations Passthrough
  // ---------------------------------------------------------------------------

  Future<void> saveConsultation(Consultation consultation) async {
    _setLoading(true);
    try {
      await _consultationService.saveConsultation(consultation);
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Consultation>> getPatientConsultations(
    String patientId, {
    String? phone,
  }) => _consultationService.getConsultationsForPatient(patientId, phone: phone);

  Future<Consultation?> getConsultationForAppointment(
    String appointmentId,
    String patientId, {
    String? phone,
  }) async {
    final list = await getPatientConsultations(patientId, phone: phone);
    return list.where((c) => c.appointmentId == appointmentId).firstOrNull;
  }

  Future<List<PrescriptionItem>> getActiveMedicationsForPatient(
    String patientId, {
    String? phone,
  }) => _consultationService.getLatestActiveMedications(
    patientId,
    phone: phone,
  );

  // ---------------------------------------------------------------------------
  // Pure Domain Calculations (Passthrough)
  // ---------------------------------------------------------------------------

  PatientReviewEligibility checkReviewEligibility({
    required List<Appointment> patientAppointments,
    required String? doctorId,
    required DateTime scheduledDate,
    String? doctorName,
    int freeReviewDays = 14,
  }) => AppointmentEngine.evaluateReviewEligibility(
    patientHistory: patientAppointments,
    doctorId: doctorId,
    targetDate: scheduledDate,
    doctorName: doctorName,
    freeReviewDays: freeReviewDays,
  );

  PaymentType calculatePaymentType({
    required List<Appointment> patientAppointments,
    required String? doctorId,
    required DateTime scheduledDate,
    int freeReviewDays = 14,
  }) => AppointmentEngine.suggestPaymentType(
    patientHistory: patientAppointments,
    doctorId: doctorId,
    targetDate: scheduledDate,
    freeReviewDays: freeReviewDays,
  );

  int getProvisionalNextToken(String doctorId, {DateTime? targetDate}) =>
      AppointmentEngine.calculateProvisionalNextToken(
        appointments: _queueDelegate.todayAppointments,
        doctorId: doctorId,
        targetDate: targetDate ?? DateTime.now(),
      );

  EstimatedConsultationWindow getProvisionalEstimatedWindow(
    String doctorId, {
    DateTime? targetDate,
  }) => AppointmentEngine.calculateProvisionalEstimatedWindow(
    appointments: _queueDelegate.todayAppointments,
    doctorId: doctorId,
    targetDate: targetDate ?? DateTime.now(),
  );

  @override
  void dispose() {
    _doctorDelegate.dispose();
    _queueDelegate.dispose();
    _catalogueDelegate.dispose();
    super.dispose();
  }
}
