import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/engines/engines.dart';
import '../models/models.dart';
import '../services/services.dart';

class ClinicProvider with ChangeNotifier {
  final BookingService _bookingService;
  final DoctorService _doctorService;
  final CatalogueService _catalogueService;
  final ChamberService _chamberService;
  final ConsultationService _consultationService;
  final PatientService _patientService;
  final Uuid _uuid;

  StreamSubscription? _appointmentSub;
  StreamSubscription? _doctorSub;
  StreamSubscription? _medicineSub;

  List<Doctor> _doctors = [];
  List<Appointment> _todayAppointments = [];
  List<Medicine> _medicines = [];
  bool _hasLoadedDoctors = false;
  bool _isLoading = false;
  bool _isOfflineFallback = false;
  DateTime? _offlineCacheTimestamp;
  DateTime? _activeListeningDate;

  bool get isOfflineFallback => _isOfflineFallback;

  DateTime? get offlineCacheTimestamp => _offlineCacheTimestamp;

  /// Active doctors eligible for OPD scheduling, walk-in booking, live queue, and chamber login.
  List<Doctor> get doctors => _doctors.where((d) => d.isActive).toList();

  /// Full doctor roster including active and retired/inactive physicians (for Owner settings).
  List<Doctor> get allDoctors => _doctors;

  /// Deactivated / retired doctors.
  List<Doctor> get inactiveDoctors =>
      _doctors.where((d) => !d.isActive).toList();

  Doctor? getDoctorById(String doctorId) =>
      _doctors.where((d) => d.id == doctorId).firstOrNull;

  bool get hasLoadedDoctors => _hasLoadedDoctors;

  List<Appointment> get todayAppointments => _todayAppointments;

  List<Medicine> get medicines => _medicines;

  bool get isLoading => _isLoading;

  int get pendingCount => _todayAppointments
      .where((a) => a.status == AppointmentStatus.pending)
      .length;

  int get waitingCount => pendingCount;

  /// Count of patients physically present at the clinic desk / lobby ready for chamber.
  int get waitingInLobbyCount => _todayAppointments
      .where(
        (a) =>
            a.visitStatus == VisitStatus.waitingInLobby &&
            a.status != AppointmentStatus.absent,
      )
      .length;

  /// Count of phone / advance reservations expected today but not yet physically checked in.
  int get expectedBookedCount => _todayAppointments
      .where(
        (a) =>
            a.visitStatus == VisitStatus.booked &&
            a.status != AppointmentStatus.absent,
      )
      .length;

  /// Count of patients currently in consultation across all active doctor chambers.
  int get inConsultationCount => _todayAppointments
      .where(
        (a) =>
            a.visitStatus == VisitStatus.inConsultation &&
            a.status != AppointmentStatus.absent,
      )
      .length;

  int get completedCount => _todayAppointments
      .where((a) => a.status == AppointmentStatus.completed)
      .length;

  int get absentCount => _todayAppointments
      .where((a) => a.status == AppointmentStatus.absent)
      .length;

  String _dashboardSearchQuery = '';

  String get dashboardSearchQuery => _dashboardSearchQuery;

  void setDashboardSearchQuery(String query) {
    final clean = query.trim().toLowerCase();
    if (_dashboardSearchQuery == clean) return;
    _dashboardSearchQuery = clean;
    notifyListeners();
  }

  void clearDashboardSearchQuery() {
    if (_dashboardSearchQuery.isEmpty) return;
    _dashboardSearchQuery = '';
    notifyListeners();
  }

  /// Filters today's live queue by optional doctor selection and active search query.
  List<Appointment> getFilteredAppointments({String? doctorId}) {
    return _todayAppointments.where((a) {
      if (doctorId != null && doctorId.isNotEmpty && a.doctorId != doctorId) {
        return false;
      }
      if (_dashboardSearchQuery.isNotEmpty) {
        final matchesPhone = a.patientPhone.contains(_dashboardSearchQuery);
        final matchesName = a.patientName.toLowerCase().contains(
          _dashboardSearchQuery,
        );
        final matchesToken = a.queueNumber.toString() == _dashboardSearchQuery;
        if (!matchesPhone && !matchesName && !matchesToken) return false;
      }
      return true;
    }).toList();
  }

  int get dailyRevenue =>
      RevenueEngine.calculateRealizedRevenue(_todayAppointments);

  ClinicProvider({
    BookingService? bookingService,
    DoctorService? doctorService,
    CatalogueService? catalogueService,
    ChamberService? chamberService,
    ConsultationService? consultationService,
    PatientService? patientService,
    Uuid? uuid,
  }) : _bookingService = bookingService ?? BookingService(),
       _doctorService = doctorService ?? DoctorService(),
       _catalogueService = catalogueService ?? CatalogueService(),
       _chamberService = chamberService ?? ChamberService(),
       _consultationService = consultationService ?? ConsultationService(),
       _patientService = patientService ?? PatientService(),
       _uuid = uuid ?? const Uuid() {
    _subscribeToDoctors();
    _subscribeToMedicines();
  }

  void startListeningToAppointments([DateTime? specificDate]) {
    final targetDate = specificDate ?? DateTime.now();

    // Idempotent: avoid re-subscribing if already streaming this exact calendar day
    if (_appointmentSub != null &&
        _activeListeningDate != null &&
        DateUtils.isSameDay(_activeListeningDate, targetDate)) {
      return;
    }
    _activeListeningDate = targetDate;
    _appointmentSub?.cancel();

    // Check if offline cached queue exists for instant display if currently empty
    if (_todayAppointments.isEmpty) {
      OfflineQueueCacheService.getCachedQueue(targetDate).then((cached) {
        if (cached != null && cached.isNotEmpty && _todayAppointments.isEmpty) {
          OfflineQueueCacheService.getCacheTimestamp(targetDate).then((ts) {
            _todayAppointments = cached;
            _isOfflineFallback = true;
            _offlineCacheTimestamp = ts;
            notifyListeners();
          });
        }
      });
    }

    _appointmentSub = _bookingService
        .getAppointmentsForDate(targetDate)
        .listen(
          (appointments) {
            _todayAppointments = appointments;
            _isOfflineFallback = false;
            _offlineCacheTimestamp = null;
            notifyListeners();
            // Silently persist to offline local cache
            unawaited(
              OfflineQueueCacheService.saveQueue(targetDate, appointments),
            );
          },
          onError: (err) async {
            // Broadband dropout or Firestore error: seamlessly fallback to offline cache
            final cached = await OfflineQueueCacheService.getCachedQueue(
              targetDate,
            );
            if (cached != null && cached.isNotEmpty) {
              final ts = await OfflineQueueCacheService.getCacheTimestamp(
                targetDate,
              );
              _todayAppointments = cached;
              _isOfflineFallback = true;
              _offlineCacheTimestamp = ts;
              notifyListeners();
            }
          },
        );
  }

  void _subscribeToDoctors() {
    _doctorSub?.cancel();
    _doctorSub = _doctorService.getDoctors().listen((doctors) {
      _doctors = doctors;
      _hasLoadedDoctors = true;
      notifyListeners();
    });
  }

  void _subscribeToMedicines() {
    _medicineSub?.cancel();
    _medicineSub = _catalogueService.getMedicines().listen((meds) {
      _medicines = meds;
      notifyListeners();
    });
  }

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
    UserRole? requestingRole,
  }) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can register new doctors.',
      );
    }
    _setLoading(true);
    try {
      final newDoctor = Doctor(
        id: _uuid.v4(),
        name: name,
        specialty: specialty,
        phone: phone,
        availableDays: days,
        blockedDates: blockedDates,
        pin: pin,
        consultationFee: consultationFee,
        freeReviewDays: freeReviewDays,
        medicalRegNumber: medicalRegNumber,
        shiftTiming: shiftTiming,
        dailyTokenLimit: dailyTokenLimit,
      );
      await _doctorService.addDoctor(newDoctor);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDoctor(Doctor doctor, {UserRole? requestingRole}) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can modify doctor profiles.',
      );
    }
    _setLoading(true);
    try {
      await _doctorService.updateDoctor(doctor);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Updates planned leave dates for a physician.
  Future<void> updateDoctorLeave(
    String doctorId,
    List<DateTime> blockedDates, {
    UserRole? requestingRole,
  }) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can modify doctor leave.',
      );
    }
    _setLoading(true);
    try {
      await _doctorService.updateDoctorLeave(doctorId, blockedDates);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sets doctor active/inactive operational status.
  /// Strictly owner-authorized.
  Future<void> setDoctorActiveStatus(
    String doctorId,
    bool isActive, {
    UserRole? requestingRole,
  }) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can change doctor active status.',
      );
    }
    _setLoading(true);
    try {
      await _doctorService.setDoctorActiveStatus(doctorId, isActive);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Patient?> searchPatient(String phoneNumber) async {
    _setLoading(true);
    try {
      return await _patientService.getPatient(phoneNumber);
    } finally {
      _setLoading(false);
    }
  }

  /// Retrieves all patients registered under the given phone number (household members).
  Future<List<Patient>> getPatientsForPhone(String phoneNumber) async {
    return await _patientService.getPatientsForPhone(phoneNumber);
  }

  /// Saves or updates a patient demographic profile.
  Future<void> savePatient(Patient patient) async {
    await _patientService.savePatient(patient);
  }

  /// Searches patients by phone number (exact or prefix) or name.
  Future<List<Patient>> searchPatients(String query) async {
    return await _patientService.searchPatients(query);
  }

  /// Fetches appointment history for a given patient identity or phone.
  Future<List<Appointment>> getAppointmentsForPatient(
    String patientId, {
    String? phone,
  }) async {
    return await _bookingService.getAppointmentsForPatient(
      patientId,
      phone: phone,
    );
  }

  /// Evaluates free review eligibility for a patient with a specific doctor.
  PatientReviewEligibility checkReviewEligibility({
    required List<Appointment> patientAppointments,
    required String? doctorId,
    required DateTime scheduledDate,
    String? doctorName,
    int freeReviewDays = 14,
  }) {
    return AppointmentEngine.evaluateReviewEligibility(
      patientHistory: patientAppointments,
      doctorId: doctorId,
      targetDate: scheduledDate,
      doctorName: doctorName,
      freeReviewDays: freeReviewDays,
    );
  }

  /// Returns [PaymentType.freeReview] if the patient visited the same doctor within review window,
  /// otherwise [PaymentType.paid].
  PaymentType calculatePaymentType({
    required List<Appointment> patientAppointments,
    required String? doctorId,
    required DateTime scheduledDate,
    int freeReviewDays = 14,
  }) {
    return AppointmentEngine.suggestPaymentType(
      patientHistory: patientAppointments,
      doctorId: doctorId,
      targetDate: scheduledDate,
      freeReviewDays: freeReviewDays,
    );
  }

  /// Returns the provisional next token number for a doctor on a target date.
  int getProvisionalNextToken(String doctorId, {DateTime? targetDate}) {
    return AppointmentEngine.calculateProvisionalNextToken(
      appointments: _todayAppointments,
      doctorId: doctorId,
      targetDate: targetDate ?? DateTime.now(),
    );
  }

  /// Returns the provisional estimated consultation window for a doctor on a target date.
  EstimatedConsultationWindow getProvisionalEstimatedWindow(
    String doctorId, {
    DateTime? targetDate,
  }) {
    return AppointmentEngine.calculateProvisionalEstimatedWindow(
      appointments: _todayAppointments,
      doctorId: doctorId,
      targetDate: targetDate ?? DateTime.now(),
    );
  }

  int get lobbyWaitingCount => _todayAppointments
      .where((a) => a.visitStatus == VisitStatus.waitingInLobby)
      .length;

  int get bookedCount => _todayAppointments
      .where((a) => a.visitStatus == VisitStatus.booked)
      .length;

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
      if (AppointmentEngine.isDateBlocked(scheduledDate)) {
        throw Exception('Selected date is a clinic holiday.');
      }

      if (AppointmentEngine.isDoctorOnLeave(
        doctor: selectedDoctor,
        date: scheduledDate,
      )) {
        final summary =
            AppointmentEngine.formatDoctorLeaveSummary(
              doctor: selectedDoctor,
              date: scheduledDate,
            ) ??
            'Doctor is on leave';
        throw Exception('$summary on this date.');
      }

      final hasDuplicate = await _bookingService.hasAppointmentForDate(
        phone: phoneNumber,
        date: scheduledDate,
        patientName: name,
        doctorId: selectedDoctor.id,
        patientId: patientId,
      );
      if (hasDuplicate) {
        throw Exception(
          'Patient "$name" already has an active appointment with ${selectedDoctor.titleName} on this date.',
        );
      }

      // Enforce: Only a patient who visited earlier with the same doctor can get a free review.
      if (paymentType == PaymentType.freeReview) {
        final patientAppts = await _bookingService.getAppointmentsForPatient(
          patientId ?? phoneNumber,
          phone: phoneNumber,
        );
        final eligibility = AppointmentEngine.evaluateReviewEligibility(
          patientHistory: patientAppts,
          doctorId: selectedDoctor.id,
          targetDate: scheduledDate,
          doctorName: selectedDoctor.name,
        );
        if (!eligibility.hasVisitedDoctorEarlier) {
          throw Exception(
            'Free Review is only allowed for patients who previously visited ${selectedDoctor.titleName}.',
          );
        }
      }

      final now = DateTime.now();
      final effectivePatientId = (patientId != null && patientId.isNotEmpty)
          ? patientId
          : 'pat_${now.millisecondsSinceEpoch}_${phoneNumber.length >= 4 ? phoneNumber.substring(phoneNumber.length - 4) : phoneNumber}';

      final patient = Patient(
        id: effectivePatientId,
        name: name,
        age: age,
        ageMonths: ageMonths,
        ageDays: ageDays,
        gender: gender,
        phoneNumber: phoneNumber,
        guardianName: guardianName,
        guardianRelation: guardianRelation,
      );
      final appointmentId = _uuid.v4();
      final queueNumber = await _bookingService.bookAppointment(
        appointmentId: appointmentId,
        patient: patient,
        visitStatus: visitStatus,
        paymentType: paymentType,
        amountCollected: amountCollected,
        scheduledDate: scheduledDate,
        doctorId: selectedDoctor.id,
        doctorName: selectedDoctor.name,
      );

      final appointment = Appointment(
        id: appointmentId,
        patientId: patient.id,
        patientPhone: phoneNumber,
        patientName: name,
        patientAgeDisplay: patient.formattedAge,
        guardianName: patient.guardianName,
        guardianRelation: patient.guardianRelation,
        visitStatus: visitStatus,
        paymentType: paymentType,
        amountCollected: amountCollected,
        queueNumber: queueNumber,
        scheduledDate: scheduledDate,
        doctorId: selectedDoctor.id,
        doctorName: selectedDoctor.name,
        checkedInAt: visitStatus == VisitStatus.waitingInLobby ? now : null,
      );
      return appointment;
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 1-tap reception check-in & payment reconciliation from dashboard or queue view.
  Future<void> checkInPatient({
    required String appointmentId,
    required PaymentType paymentType,
    required int amountCollected,
  }) async {
    try {
      await _bookingService.checkInPatient(
        appointmentId: appointmentId,
        paymentType: paymentType,
        amountCollected: amountCollected,
      );
    } catch (e) {
      debugPrint('Error checking in patient: $e');
      rethrow;
    }
  }

  /// Direct admission of patient from lobby into chamber, updating visitStatus to inConsultation.
  Future<void> admitPatientToChamber(String appointmentId) async {
    try {
      await _bookingService.admitPatientToChamber(appointmentId);
    } catch (e) {
      debugPrint('Error admitting patient to chamber: $e');
      rethrow;
    }
  }

  Future<void> updateAppointmentStatus(
    String id,
    String status,
    String paymentType,
    int amount, {
    VisitStatus? visitStatus,
  }) async {
    try {
      final pType = PaymentType.values.firstWhere(
        (e) => e.name == paymentType,
        orElse: () => PaymentType.paidCash,
      );

      final statusEnum = AppointmentStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => AppointmentStatus.pending,
      );

      await _bookingService.updateAppointmentStatus(
        id,
        statusEnum,
        visitStatus: visitStatus,
        collectedAmount: amount,
        paymentType: pType,
      );
    } catch (e) {
      debugPrint('Error updating status: $e');
      rethrow;
    }
  }

  /// 1-tap reception action to mark a patient absent (no-show), setting amount to 0
  /// and strictly preserving the audit-proof token slot per Invariant #1.
  Future<void> markAppointmentAbsent(Appointment appointment) async {
    try {
      await _bookingService.updateAppointmentStatus(
        appointment.id,
        AppointmentStatus.absent,
        collectedAmount: 0,
        paymentType: appointment.paymentType,
      );
    } catch (e) {
      debugPrint('Error marking appointment absent: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Chamber Zero-Touch Real-Time Session
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
      await _bookingService.admitPatientToChamber(appointment.id);
    } catch (e) {
      debugPrint('Error notifying consultation started: $e');
    }
  }

  /// Pauses an active consultation encounter, marks appointment paused in waiting lobby,
  /// and frees doctor's chamber so the next patient can be dispatched or called.
  Future<void> pauseConsultation({
    required String appointmentId,
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      await _bookingService.pauseAppointment(appointmentId);
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

  Stream<List<Appointment>> streamUpcomingAppointments({int daysAhead = 7}) {
    return _bookingService.getUpcomingAppointments(daysAhead: daysAhead);
  }

  Future<void> updateDoctorSearchPreference(
    String doctorId,
    String searchPreference,
  ) async {
    try {
      await _doctorService.updateDoctorSearchPreference(
        doctorId,
        searchPreference,
      );
    } catch (e) {
      debugPrint('Error updating doctor search preference: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Longitudinal Consultations
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
  }) async {
    return await _consultationService.getConsultationsForPatient(
      patientId,
      phone: phone,
    );
  }

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
  }) async {
    return await _consultationService.getLatestActiveMedications(
      patientId,
      phone: phone,
    );
  }

  // ---------------------------------------------------------------------------
  // Master Medicine Catalogue
  // ---------------------------------------------------------------------------

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
    _setLoading(true);
    try {
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
    } finally {
      _setLoading(false);
    }
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
    _setLoading(true);
    try {
      await _catalogueService.deleteMedicine(medicineId);
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
      return await _catalogueService.deduplicateMedicines();
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
      await _catalogueService.ensureDefaultMedicinesExist();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Medicine>> searchMedicines(String query) async {
    return await _catalogueService.searchMedicines(query);
  }

  /// Bulk closes today's OPD session for a given doctor when absent or on emergency leave.
  /// Strictly owner-authorized. All un-consulted tokens are atomically marked absent with ₹0 collection.
  Future<int> closeDoctorSession({
    required String doctorId,
    required DateTime date,
    UserRole? requestingRole,
    String reason = 'Doctor absent / session closed',
  }) async {
    if (requestingRole != null && !requestingRole.isOwner) {
      throw Exception(
        'Permission Denied: Only clinic administrators (owner) can close doctor sessions in bulk.',
      );
    }
    _setLoading(true);
    try {
      final count = await _bookingService.closeDoctorSessionForDate(
        doctorId: doctorId,
        date: date,
        reason: reason,
      );
      return count;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
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
