import 'package:cloud_firestore/cloud_firestore.dart';

import 'diagnostic_investigation.dart';
import 'prescription_item.dart';
import 'vitals.dart';

/// Represents an immutable, append-only clinical consultation event.
/// Prescriptions and consultations are never mutated on follow-up;
/// subsequent encounters record reconciliation states (CONTINUE, STOP, START).
class Consultation {
  final String id;
  final String appointmentId;
  final String patientId;
  final String patientPhone;
  final String patientName;
  final int patientAge;
  final String? patientAgeDisplay;
  final String? guardianName;
  final String? guardianRelation;
  final String patientGender;
  final String doctorId;
  final String doctorName;
  final String? doctorRegNumber;
  final DateTime createdAt;

  // Step 2: Vitals & Clinical Examination
  final Vitals? vitals;
  final List<String> chiefComplaints;
  final String? clinicalExamination;
  final List<String> provisionalDiagnosis;

  // Step 3: Diagnostic Investigations Review
  final List<DiagnosticInvestigationReview> reviewedInvestigations;

  // Step 4: Medication Reconciliation & Prescribing
  final List<PrescriptionItem> prescriptionItems;

  // Step 5: Advice & Follow-up
  final List<OrderedTest> orderedTests;
  final String? adviceNotes;
  final DateTime? nextFollowUpDate;

  const Consultation({
    required this.id,
    required this.appointmentId,
    String? patientId,
    required this.patientPhone,
    required this.patientName,
    required this.patientAge,
    this.patientAgeDisplay,
    this.guardianName,
    this.guardianRelation,
    required this.patientGender,
    required this.doctorId,
    required this.doctorName,
    this.doctorRegNumber,
    required this.createdAt,
    this.vitals,
    this.chiefComplaints = const [],
    this.clinicalExamination,
    this.provisionalDiagnosis = const [],
    this.reviewedInvestigations = const [],
    this.prescriptionItems = const [],
    this.orderedTests = const [],
    this.adviceNotes,
    this.nextFollowUpDate,
  }) : patientId = (patientId == null || patientId == '')
           ? patientPhone
           : patientId;

  /// Medications that are active for today's visit (START + CONTINUE)
  List<PrescriptionItem> get activePrescriptions =>
      prescriptionItems.where((p) => p.isActive).toList();

  /// Medications newly initiated during this consultation
  List<PrescriptionItem> get startedPrescriptions => prescriptionItems
      .where((p) => p.action == MedicationAction.start)
      .toList();

  /// Past ongoing medications that were reconciled and continued
  List<PrescriptionItem> get continuedPrescriptions => prescriptionItems
      .where((p) => p.action == MedicationAction.continueAction)
      .toList();

  /// Medications discontinued during this consultation
  List<PrescriptionItem> get stoppedPrescriptions => prescriptionItems
      .where((p) => p.action == MedicationAction.stop)
      .toList();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientPhone': patientPhone,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientAgeDisplay': patientAgeDisplay,
      'guardianName': guardianName,
      'guardianRelation': guardianRelation,
      'patientGender': patientGender,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorRegNumber': doctorRegNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'vitals': vitals?.toJson(),
      'chiefComplaints': chiefComplaints,
      'clinicalExamination': clinicalExamination,
      'provisionalDiagnosis': provisionalDiagnosis,
      'reviewedInvestigations': reviewedInvestigations
          .map((r) => r.toJson())
          .toList(),
      'prescriptionItems': prescriptionItems.map((p) => p.toJson()).toList(),
      'orderedTests': orderedTests.map((o) => o.toJson()).toList(),
      'adviceNotes': adviceNotes,
      'nextFollowUpDate': nextFollowUpDate != null
          ? Timestamp.fromDate(nextFollowUpDate!)
          : null,
    };
  }

  factory Consultation.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt;
    final rawCreatedAt = json['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    DateTime? parsedFollowUp;
    final rawFollowUp = json['nextFollowUpDate'];
    if (rawFollowUp is Timestamp) {
      parsedFollowUp = rawFollowUp.toDate();
    } else if (rawFollowUp is DateTime) {
      parsedFollowUp = rawFollowUp;
    } else if (rawFollowUp is String) {
      parsedFollowUp = DateTime.tryParse(rawFollowUp);
    }

    final phone = json['patientPhone'] as String? ?? '';
    final patId = json['patientId'] as String?;

    return Consultation(
      id: json['id'] as String? ?? '',
      appointmentId: json['appointmentId'] as String? ?? '',
      patientId: (patId != null && patId.isNotEmpty) ? patId : phone,
      patientPhone: phone,
      patientName: json['patientName'] as String? ?? 'Unknown',
      patientAge: (json['patientAge'] as num?)?.toInt() ?? 0,
      patientAgeDisplay: json['patientAgeDisplay'] as String?,
      guardianName: json['guardianName'] as String?,
      guardianRelation: json['guardianRelation'] as String?,
      patientGender: json['patientGender'] as String? ?? 'Unspecified',
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      doctorRegNumber: json['doctorRegNumber'] as String?,
      createdAt: parsedCreatedAt,
      vitals: json['vitals'] != null
          ? Vitals.fromJson(Map<String, dynamic>.from(json['vitals'] as Map))
          : null,
      chiefComplaints:
          (json['chiefComplaints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      clinicalExamination: json['clinicalExamination'] as String?,
      provisionalDiagnosis:
          (json['provisionalDiagnosis'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      reviewedInvestigations:
          (json['reviewedInvestigations'] as List<dynamic>?)
              ?.map(
                (e) => DiagnosticInvestigationReview.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
      prescriptionItems:
          (json['prescriptionItems'] as List<dynamic>?)
              ?.map(
                (e) => PrescriptionItem.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
      orderedTests:
          (json['orderedTests'] as List<dynamic>?)
              ?.map(
                (e) =>
                    OrderedTest.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          const [],
      adviceNotes: json['adviceNotes'] as String?,
      nextFollowUpDate: parsedFollowUp,
    );
  }

  Consultation copyWith({
    String? id,
    String? appointmentId,
    String? patientId,
    String? patientPhone,
    String? patientName,
    int? patientAge,
    String? patientAgeDisplay,
    String? guardianName,
    String? guardianRelation,
    String? patientGender,
    String? doctorId,
    String? doctorName,
    String? doctorRegNumber,
    DateTime? createdAt,
    Vitals? vitals,
    List<String>? chiefComplaints,
    String? clinicalExamination,
    List<String>? provisionalDiagnosis,
    List<DiagnosticInvestigationReview>? reviewedInvestigations,
    List<PrescriptionItem>? prescriptionItems,
    List<OrderedTest>? orderedTests,
    String? adviceNotes,
    DateTime? nextFollowUpDate,
  }) {
    return Consultation(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      patientPhone: patientPhone ?? this.patientPhone,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientAgeDisplay: patientAgeDisplay ?? this.patientAgeDisplay,
      guardianName: guardianName ?? this.guardianName,
      guardianRelation: guardianRelation ?? this.guardianRelation,
      patientGender: patientGender ?? this.patientGender,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorRegNumber: doctorRegNumber ?? this.doctorRegNumber,
      createdAt: createdAt ?? this.createdAt,
      vitals: vitals ?? this.vitals,
      chiefComplaints: chiefComplaints ?? this.chiefComplaints,
      clinicalExamination: clinicalExamination ?? this.clinicalExamination,
      provisionalDiagnosis: provisionalDiagnosis ?? this.provisionalDiagnosis,
      reviewedInvestigations:
          reviewedInvestigations ?? this.reviewedInvestigations,
      prescriptionItems: prescriptionItems ?? this.prescriptionItems,
      orderedTests: orderedTests ?? this.orderedTests,
      adviceNotes: adviceNotes ?? this.adviceNotes,
      nextFollowUpDate: nextFollowUpDate ?? this.nextFollowUpDate,
    );
  }
}
