import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../models/patient.dart';
import '../../models/user_role.dart';
import '../../services/booking_service.dart';
import '../../services/offline_queue_cache_service.dart';

/// Delegate controller responsible for live queue streaming, offline cache fallback,
/// midnight calendar rollover observation, and appointment lifecycle actions.
class LiveQueueDelegate {
  final BookingService _bookingService;
  final Uuid _uuid;
  final VoidCallback _notifyListeners;

  StreamSubscription? _appointmentSub;
  List<Appointment> _todayAppointments = [];
  bool _isOfflineFallback = false;
  DateTime? _offlineCacheTimestamp;
  DateTime? _activeListeningDate;
  Timer? _midnightObserverTimer;
  Timer? _cacheDebounceTimer;
  bool _isCustomDateSelected = false;
  String _dashboardSearchQuery = '';

  LiveQueueDelegate({
    BookingService? bookingService,
    Uuid? uuid,
    bool enableMidnightObserver = true,
    required this._notifyListeners,
  }) : _bookingService = bookingService ?? BookingService(),
       _uuid = uuid ?? const Uuid() {
    if (enableMidnightObserver) {
      _startMidnightDateObserver();
    }
  }

  bool get isOfflineFallback => _isOfflineFallback;
  DateTime? get offlineCacheTimestamp => _offlineCacheTimestamp;
  bool get isCustomDateSelected => _isCustomDateSelected;
  DateTime? get activeListeningDate => _activeListeningDate;
  List<Appointment> get todayAppointments => _todayAppointments;
  String get dashboardSearchQuery => _dashboardSearchQuery;

  int get pendingCount => _todayAppointments
      .where((a) => a.status == AppointmentStatus.pending)
      .length;

  int get waitingCount => pendingCount;

  int get waitingInLobbyCount => _todayAppointments
      .where(
        (a) =>
            a.visitStatus == VisitStatus.waitingInLobby &&
            a.status != AppointmentStatus.absent,
      )
      .length;

  int get expectedBookedCount => _todayAppointments
      .where(
        (a) =>
            a.visitStatus == VisitStatus.booked &&
            a.status != AppointmentStatus.absent,
      )
      .length;

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

  int get dailyRevenue =>
      RevenueEngine.calculateRealizedRevenue(_todayAppointments);

  int get lobbyWaitingCount => _todayAppointments
      .where((a) => a.visitStatus == VisitStatus.waitingInLobby)
      .length;

  int get bookedCount => _todayAppointments
      .where((a) => a.visitStatus == VisitStatus.booked)
      .length;

  void setDashboardSearchQuery(String query) {
    final clean = query.trim().toLowerCase();
    if (_dashboardSearchQuery == clean) return;
    _dashboardSearchQuery = clean;
    _notifyListeners();
  }

  void clearDashboardSearchQuery() {
    if (_dashboardSearchQuery.isEmpty) return;
    _dashboardSearchQuery = '';
    _notifyListeners();
  }

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

  void _startMidnightDateObserver() {
    _midnightObserverTimer?.cancel();
    _midnightObserverTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => checkAndHandleMidnightRollover(),
    );
  }

  void checkAndHandleMidnightRollover([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    if (_activeListeningDate != null &&
        !_isCustomDateSelected &&
        !DateUtils.isSameDay(_activeListeningDate, now)) {
      _todayAppointments = [];
      _appointmentSub?.cancel();
      _appointmentSub = null;
      _activeListeningDate = null;
      startListeningToAppointments(now);
      _isCustomDateSelected = false;
      _notifyListeners();
    }
  }

  void startListeningToAppointments([DateTime? specificDate]) {
    _isCustomDateSelected = specificDate != null &&
        !DateUtils.isSameDay(specificDate, DateTime.now());
    final targetDate = specificDate ?? DateTime.now();

    // Idempotent: avoid re-subscribing if already streaming this exact calendar day
    if (_appointmentSub != null &&
        _activeListeningDate != null &&
        DateUtils.isSameDay(_activeListeningDate, targetDate)) {
      return;
    }
    _activeListeningDate = targetDate;
    _appointmentSub?.cancel();
    _cacheDebounceTimer?.cancel();

    // Check if offline cached queue exists for instant display if currently empty
    if (_todayAppointments.isEmpty) {
      OfflineQueueCacheService.getCachedQueue(targetDate).then((cached) {
        if (cached != null && cached.isNotEmpty && _todayAppointments.isEmpty) {
          OfflineQueueCacheService.getCacheTimestamp(targetDate).then((ts) {
            _todayAppointments = cached;
            _isOfflineFallback = true;
            _offlineCacheTimestamp = ts;
            _notifyListeners();
          }).catchError((_) {});
        }
      }).catchError((_) {});
    }

    _appointmentSub = _bookingService
        .getAppointmentsForDate(targetDate)
        .listen(
          (appointments) {
            _todayAppointments = appointments;
            _isOfflineFallback = false;
            _offlineCacheTimestamp = null;
            _notifyListeners();
            // AUDIT-15: Debounce offline cache write (3 seconds) to prevent UI frame drops
            // and disk thrashing on rapid consecutive Firestore snapshot bursts.
            _cacheDebounceTimer?.cancel();
            _cacheDebounceTimer = Timer(const Duration(seconds: 3), () {
              unawaited(
                OfflineQueueCacheService.saveQueue(targetDate, appointments)
                    .catchError((_) {}),
              );
            });
          },
          onError: (err) async {
            try {
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
                _notifyListeners();
              }
            } catch (e) {
              debugPrint('Offline queue cache fallback error: $e');
            }
          },
        );
  }

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
    String? carriedOverAppointmentId,
    int? carriedOverAmount,
    DateTime? carriedOverDate,
  }) async {
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

    if (!AppointmentEngine.isDoctorAvailableOnDate(
      doctor: selectedDoctor,
      date: scheduledDate,
    )) {
      const dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final dayName = dayNames[scheduledDate.weekday - 1];
      final docTitle = selectedDoctor.titleName;
      final schedule = selectedDoctor.availableDays.join(', ');
      throw Exception(
        '$docTitle does not consult on ${dayName}s (Schedule: $schedule).',
      );
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
        freeReviewDays: selectedDoctor.freeReviewDays,
      );
      if (!eligibility.hasVisitedDoctorEarlier) {
        throw Exception(
          'Free Review is only allowed for patients who previously visited ${selectedDoctor.titleName}.',
        );
      }
      if (eligibility.isReviewAlreadyConsumed) {
        throw Exception(
          'Free Review has already been consumed for the previous consultation with ${selectedDoctor.titleName}.',
        );
      }
      if (!eligibility.isWithinReviewPeriod) {
        throw Exception(
          'Free review window has expired for ${selectedDoctor.titleName} (${eligibility.allowedReviewDays}-day policy).',
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
      carriedOverAppointmentId: carriedOverAppointmentId,
      carriedOverAmount: carriedOverAmount,
      carriedOverDate: carriedOverDate,
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
      carriedOverAppointmentId: carriedOverAppointmentId,
      carriedOverAmount: carriedOverAmount,
      carriedOverDate: carriedOverDate,
    );
    return appointment;
  }

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
    String? refundStatus,
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
        refundStatus: refundStatus,
      );
    } catch (e) {
      debugPrint('Error updating status: $e');
      rethrow;
    }
  }

  Future<void> markAppointmentAbsent(Appointment appointment) async {
    try {
      final hasPaid = appointment.amountCollected > 0;
      await _bookingService.updateAppointmentStatus(
        appointment.id,
        AppointmentStatus.absent,
        collectedAmount: appointment.amountCollected,
        paymentType: appointment.paymentType,
        refundStatus: hasPaid ? 'pending_refund' : 'none',
      );
    } catch (e) {
      debugPrint('Error marking appointment absent: $e');
      rethrow;
    }
  }

  Future<void> pauseAppointment(String appointmentId) async {
    await _bookingService.pauseAppointment(appointmentId);
  }

  Future<void> returnAppointmentToLobby(String appointmentId) async {
    await _bookingService.returnAppointmentToLobby(appointmentId);
  }

  Stream<List<Appointment>> streamUpcomingAppointments({int daysAhead = 7}) {
    return _bookingService.getUpcomingAppointments(daysAhead: daysAhead);
  }

  Future<List<Appointment>> getAppointmentsForPatient(
    String patientId, {
    String? phone,
  }) async {
    return await _bookingService.getAppointmentsForPatient(
      patientId,
      phone: phone,
    );
  }

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
    return await _bookingService.closeDoctorSessionForDate(
      doctorId: doctorId,
      date: date,
      reason: reason,
    );
  }

  void dispose() {
    _midnightObserverTimer?.cancel();
    _appointmentSub?.cancel();
    _cacheDebounceTimer?.cancel();
  }
}
