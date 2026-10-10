import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/consultation.dart';
import '../models/medicine.dart';
import '../models/prescription_item.dart';
import 'booking_service.dart';
import 'consultation_service.dart';
import 'chamber_service.dart';
import 'patient_service.dart';
import 'doctor_service.dart';
import 'catalogue_service.dart';

export 'firestore_paths.dart';
export 'booking_service.dart';
export 'consultation_service.dart';
export 'chamber_service.dart';
export 'patient_service.dart';
export 'doctor_service.dart';
export 'catalogue_service.dart';

/// Unified clinical services facade providing backward-compatible access
/// to modular single-responsibility backend services.
class FirebaseService {
  final BookingService _bookingService;
  final ConsultationService _consultationService;
  final ChamberService _chamberService;
  final PatientService _patientService;
  final DoctorService _doctorService;
  final CatalogueService _catalogueService;

  FirebaseService({
    FirebaseFirestore? firestore,
    BookingService? bookingService,
    ConsultationService? consultationService,
    ChamberService? chamberService,
    PatientService? patientService,
    DoctorService? doctorService,
    CatalogueService? catalogueService,
  })  : _bookingService =
            bookingService ?? BookingService(firestore: firestore),
        _consultationService =
            consultationService ?? ConsultationService(firestore: firestore),
        _chamberService =
            chamberService ?? ChamberService(firestore: firestore),
        _patientService =
            patientService ?? PatientService(firestore: firestore),
        _doctorService = doctorService ?? DoctorService(firestore: firestore),
        _catalogueService =
            catalogueService ?? CatalogueService(firestore: firestore);

  // Sub-service accessors for granular domain consumption
  BookingService get booking => _bookingService;
  ConsultationService get consultation => _consultationService;
  ChamberService get chamber => _chamberService;
  PatientService get patient => _patientService;
  DoctorService get doctor => _doctorService;
  CatalogueService get catalogue => _catalogueService;

  // ---------------------------------------------------------------------------
  // Patients
  // ---------------------------------------------------------------------------

  Future<Patient?> getPatient(String phoneNumber) =>
      _patientService.getPatient(phoneNumber);

  // ---------------------------------------------------------------------------
  // Appointments & Queue Bookings
  // ---------------------------------------------------------------------------

  Future<int> bookAppointment({
    required String appointmentId,
    required Patient patient,
    required PaymentType paymentType,
    required int amountCollected,
    required DateTime scheduledDate,
    required String doctorId,
    required String doctorName,
  }) =>
      _bookingService.bookAppointment(
        appointmentId: appointmentId,
        patient: patient,
        paymentType: paymentType,
        amountCollected: amountCollected,
        scheduledDate: scheduledDate,
        doctorId: doctorId,
        doctorName: doctorName,
      );

  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status, {
    int? collectedAmount,
    PaymentType? paymentType,
  }) =>
      _bookingService.updateAppointmentStatus(
        appointmentId,
        status,
        collectedAmount: collectedAmount,
        paymentType: paymentType,
      );

  Stream<List<Appointment>> getAppointmentsForDate(DateTime date) =>
      _bookingService.getAppointmentsForDate(date);

  Stream<List<Appointment>> getAppointmentsForDoctorAndDate(
    String doctorId,
    DateTime date,
  ) =>
      _bookingService.getAppointmentsForDoctorAndDate(doctorId, date);

  Future<List<Appointment>> getAppointmentsForPatient(String phone) =>
      _bookingService.getAppointmentsForPatient(phone);

  Future<bool> hasAppointmentForDate(String phone, DateTime date) =>
      _bookingService.hasAppointmentForDate(phone, date);

  // ---------------------------------------------------------------------------
  // Chamber Real-Time Session (Zero-Touch Sync)
  // ---------------------------------------------------------------------------

  Future<void> callTokenIntoChamber({
    required String doctorId,
    required DateTime date,
    required Appointment appointment,
  }) =>
      _chamberService.callTokenIntoChamber(
        doctorId: doctorId,
        date: date,
        appointment: appointment,
      );

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamChamberSession(
    String doctorId,
    DateTime date,
  ) =>
      _chamberService.streamChamberSession(doctorId, date);

  Future<void> notifyConsultationEnded({
    required String doctorId,
    required DateTime date,
    required int queueNumber,
    required String patientName,
  }) =>
      _chamberService.notifyConsultationEnded(
        doctorId: doctorId,
        date: date,
        queueNumber: queueNumber,
        patientName: patientName,
      );

  Future<void> notifyReadyForNext({
    required String doctorId,
    required DateTime date,
  }) =>
      _chamberService.notifyReadyForNext(
        doctorId: doctorId,
        date: date,
      );

  Future<void> notifyConsultationStarted({
    required String doctorId,
    required DateTime date,
    required Appointment appointment,
  }) =>
      _chamberService.notifyConsultationStarted(
        doctorId: doctorId,
        date: date,
        appointment: appointment,
      );

  Future<void> clearChamberSession(String doctorId, DateTime date) =>
      _chamberService.clearChamberSession(doctorId, date);

  // ---------------------------------------------------------------------------
  // Doctors
  // ---------------------------------------------------------------------------

  Future<void> addDoctor(Doctor doctor) => _doctorService.addDoctor(doctor);

  Future<void> updateDoctorSearchPreference(
    String doctorId,
    String searchPreference,
  ) =>
      _doctorService.updateDoctorSearchPreference(doctorId, searchPreference);

  Stream<List<Doctor>> getDoctors() => _doctorService.getDoctors();

  Future<void> deleteDoctor(String doctorId) =>
      _doctorService.deleteDoctor(doctorId);

  // ---------------------------------------------------------------------------
  // Longitudinal Consultations (Append-Only)
  // ---------------------------------------------------------------------------

  Future<void> saveConsultation(Consultation consultation) =>
      _consultationService.saveConsultation(consultation);

  Future<List<Consultation>> getConsultationsForPatient(String phone) =>
      _consultationService.getConsultationsForPatient(phone);

  Future<Consultation?> getLatestConsultationForPatient(String phone) =>
      _consultationService.getLatestConsultationForPatient(phone);

  Future<List<PrescriptionItem>> getLatestActiveMedications(String phone) =>
      _consultationService.getLatestActiveMedications(phone);

  // ---------------------------------------------------------------------------
  // Master Medicine Catalogue
  // ---------------------------------------------------------------------------

  Future<void> addMedicine(Medicine medicine) =>
      _catalogueService.addMedicine(medicine);

  Future<void> deleteMedicine(String medicineId) =>
      _catalogueService.deleteMedicine(medicineId);

  Stream<List<Medicine>> getMedicines() => _catalogueService.getMedicines();

  Future<void> ensureDefaultMedicinesExist() =>
      _catalogueService.ensureDefaultMedicinesExist();

  Future<int> deduplicateMedicines() =>
      _catalogueService.deduplicateMedicines();

  Future<List<Medicine>> searchMedicines(String query) =>
      _catalogueService.searchMedicines(query);
}
