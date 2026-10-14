import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/consultation.dart';
import '../../models/patient.dart';
import '../../providers/clinic_provider.dart';
import '../booking/add_appointment_dialog.dart';
import 'doctor_consultation_accordion.dart';

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
    final isMobile = MediaQuery.of(context).size.width < 600;

    final bookingButton = FilledButton.icon(
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
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
            if (!isMobile) ...[
              const SizedBox(width: 12),
              bookingButton,
            ],
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: bookingButton),
        ],
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
              return DoctorConsultationAccordion(
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
