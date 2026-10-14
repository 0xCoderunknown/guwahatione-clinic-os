import 'package:flutter/material.dart';

import '../../models/consultation.dart';
import '../../models/prescription_item.dart';
import '../../screens/prescription_print_screen.dart';
import '../../utils/formatters.dart';

/// Collapsible accordion panel presenting clinical prescriptions and encounter summary for a specific doctor.
class DoctorConsultationAccordion extends StatelessWidget {
  final Consultation latestConsultation;
  final int totalVisitsWithDoctor;
  final List<String> patientAllergies;

  const DoctorConsultationAccordion({
    super.key,
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
