import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/consultation.dart';
import '../../models/patient.dart';
import '../../models/prescription_item.dart';
import '../../providers/clinic_provider.dart';
import '../../screens/prescription_print_screen.dart';
import '../../utils/formatters.dart';
import '../booking/add_appointment_dialog.dart';

/// Card displaying patient demographic overview and collapsible doctor consultation accordions.
class PatientLookupCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback? onBookWalkIn;

  const PatientLookupCard({
    super.key,
    required this.patient,
    this.onBookWalkIn,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Patient Master Header
            _buildPatientHeader(context),
            const SizedBox(height: 14),

            // 2. Multi-Doctor Consultation History Accordions
            _buildConsultationsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Initials Avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.teal.shade50,
          child: Text(
            patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Demographic Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '${patient.age > 0 ? '${patient.age} Y' : 'Age —'} • ${patient.gender}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          patient.phoneNumber,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (patient.allergies.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 13,
                            color: Color(0xFFB91C1C),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Allergies: ${patient.allergies.join(', ')}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Quick Booking Action
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            if (onBookWalkIn != null) {
              onBookWalkIn!();
            } else {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AddAppointmentDialog(initialPatient: patient),
              );
            }
          },
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text(
            'Book Walk-In',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationsSection(BuildContext context) {
    final clinic = Provider.of<ClinicProvider>(context, listen: false);

    return FutureBuilder<List<Consultation>>(
      future: clinic.getPatientConsultations(patient.phoneNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final consultations = snapshot.data ?? [];

        if (consultations.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Text(
                  'No past clinical encounters recorded yet. Patient registered via counter check-in.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        // Partition consultations by Doctor (latest consultation per doctor)
        final Map<String, List<Consultation>> consultationsByDoctor = {};
        for (final c in consultations) {
          consultationsByDoctor.putIfAbsent(c.doctorId, () => []).add(c);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.history_edu_rounded,
                  size: 16,
                  color: Color(0xFF475569),
                ),
                const SizedBox(width: 6),
                Text(
                  'Clinical Consultations by Physician (${consultationsByDoctor.length})',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...consultationsByDoctor.entries.map((entry) {
              final docConsultations = entry.value;
              final latest = docConsultations.first;
              return _DoctorConsultationAccordion(
                latestConsultation: latest,
                totalVisitsWithDoctor: docConsultations.length,
                patientAllergies: patient.allergies,
              );
            }),
          ],
        );
      },
    );
  }
}

/// Collapsible accordion panel presenting clinical prescriptions and encounter summary for a specific doctor.
class _DoctorConsultationAccordion extends StatelessWidget {
  final Consultation latestConsultation;
  final int totalVisitsWithDoctor;
  final List<String> patientAllergies;

  const _DoctorConsultationAccordion({
    required this.latestConsultation,
    required this.totalVisitsWithDoctor,
    required this.patientAllergies,
  });

  @override
  Widget build(BuildContext context) {
    final activeMeds = latestConsultation.activePrescriptions;
    final doctorTitle = AppFormatters.doctorTitle(latestConsultation.doctorName);
    final visitDate = AppFormatters.date(latestConsultation.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.indigo.shade50,
            child: const Icon(
              Icons.medical_services_outlined,
              size: 16,
              color: Colors.indigo,
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  doctorTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$totalVisitsWithDoctor ${totalVisitsWithDoctor == 1 ? 'visit' : 'visits'}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Last Encounter: $visitDate • ${activeMeds.length} ${activeMeds.length == 1 ? 'Active Med' : 'Active Meds'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),

                  // Chief Complaints & Provisional Diagnosis
                  if (latestConsultation.chiefComplaints.isNotEmpty ||
                      latestConsultation.provisionalDiagnosis.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (latestConsultation.chiefComplaints.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Chief Complaints',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  latestConsultation.chiefComplaints.join(', '),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (latestConsultation.provisionalDiagnosis.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Provisional Diagnosis',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  latestConsultation.provisionalDiagnosis.join(', '),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Active Prescriptions Header & List
                  const Text(
                    'Active Prescribed Regimen',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (activeMeds.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'No ongoing active medications recorded for this consultation.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...activeMeds.map((med) => _buildPrescriptionItemRow(med)),

                  // Advice & Next Review Date
                  if (latestConsultation.adviceNotes != null &&
                      latestConsultation.adviceNotes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Advice: ${latestConsultation.adviceNotes}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          if (latestConsultation.nextFollowUpDate != null)
                            Text(
                              'Next Review: ${AppFormatters.date(latestConsultation.nextFollowUpDate)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF99F6E4)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrescriptionPrintScreen(
                              consultation: latestConsultation,
                              patientAllergies: patientAllergies,
                              doctorRegNumber: latestConsultation.doctorRegNumber,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.print_outlined, size: 14),
                      label: const Text(
                        'View Prescription',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionItemRow(PrescriptionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicineName.isNotEmpty
                      ? item.medicineName
                      : (item.unlistedName ?? 'Medication'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (item.composition.isNotEmpty)
                  Text(
                    item.composition,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.frequency.isNotEmpty
                  ? '${item.frequency} (${item.timing})'
                  : item.timing,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF334155),
              ),
            ),
          ),
          Text(
            item.durationDays != null ? '${item.durationDays}d' : 'Ongoing',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: item.action == MedicationAction.start
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.action.name.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: item.action == MedicationAction.start
                    ? const Color(0xFF15803D)
                    : const Color(0xFF1D4ED8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
