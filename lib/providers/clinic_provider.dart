import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/engines/engines.dart';
import '../models/appointment.dart';
import '../models/chamber_session.dart';
import '../models/consultation.dart';
import '../models/doctor.dart';
import '../models/medicine.dart';
import '../models/patient.dart';
import '../models/patient_review_eligibility.dart';
import '../models/prescription_item.dart';
import '../models/user_role.dart';
import '../services/booking_service.dart';
import '../services/catalogue_service.dart';
import '../services/chamber_service.dart';
import '../services/consultation_service.dart';
import '../services/doctor_service.dart';
import '../services/offline_queue_cache_service.dart';
import '../services/patient_service.dart';
import '../services/sound_service.dart';

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

  List<Doctor> get doctors => _doctors;

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
    String pin = '1234',
    int consultationFee = 500,
    int freeReviewDays = 14,
    String? medicalRegNumber,
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
        blockedDates: [],
        pin: pin,
        consultationFee: consultationFee,
        freeReviewDays: freeReviewDays,
        medicalRegNumber: medicalRegNumber,
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

  Future<Patient?> searchPatient(String phoneNumber) async {
    _setLoading(true);
    try {
      return await _patientService.getPatient(phoneNumber);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches appointment history for a given patient.
  Future<List<Appointment>> getAppointmentsForPatient(
    String phoneNumber,
  ) async {
    return await _bookingService.getAppointmentsForPatient(phoneNumber);
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

  Future<void> bookAppointment({
    required String phoneNumber,
    required String name,
    required int age,
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

      final hasDuplicate = await _bookingService.hasAppointmentForDate(
        phone: phoneNumber,
        date: scheduledDate,
        patientName: name,
        doctorId: selectedDoctor.id,
      );
      if (hasDuplicate) {
        throw Exception(
          'Patient "$name" already has an active appointment with Dr. ${selectedDoctor.name} on this date.',
        );
      }

      // Enforce: Only a patient who visited earlier with the same doctor can get a free review.
      if (paymentType == PaymentType.freeReview) {
        final patientAppts = await _bookingService.getAppointmentsForPatient(
          phoneNumber,
        );
        final eligibility = AppointmentEngine.evaluateReviewEligibility(
          patientHistory: patientAppts,
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
        phoneNumber: phoneNumber,
      );
      await _bookingService.bookAppointment(
        appointmentId: _uuid.v4(),
        patient: patient,
        visitStatus: visitStatus,
        paymentType: paymentType,
        amountCollected: amountCollected,
        scheduledDate: scheduledDate,
        doctorId: selectedDoctor.id,
        doctorName: selectedDoctor.name,
      );
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
    } catch (e) {
      debugPrint('Error notifying consultation started: $e');
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

  Future<List<Consultation>> getPatientConsultations(String phone) async {
    return await _consultationService.getConsultationsForPatient(phone);
  }

  Future<Consultation?> getConsultationForAppointment(
    String appointmentId,
    String phone,
  ) async {
    final list = await getPatientConsultations(phone);
    return list.where((c) => c.appointmentId == appointmentId).firstOrNull;
  }

  Future<List<PrescriptionItem>> getActiveMedicationsForPatient(
    String phone,
  ) async {
    return await _consultationService.getLatestActiveMedications(phone);
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
