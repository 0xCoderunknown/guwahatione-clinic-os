import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../models/consultation.dart';
import '../../utils/formatters.dart';

/// Top printable section: digital letterhead / pre-printed spacer + patient demographics & allergies strip.
class PrintHeaderAndDemographics extends StatelessWidget {
  final Consultation consultation;
  final Appointment? appointment;
  final List<String> patientAllergies;
  final String? doctorSpecialty;
  final bool usePrePrintedLetterhead;

  const PrintHeaderAndDemographics({
    super.key,
    required this.consultation,
    this.appointment,
    this.patientAllergies = const [],
    this.doctorSpecialty,
    required this.usePrePrintedLetterhead,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (usePrePrintedLetterhead)
          Container(
            height: 130,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
              color: Colors.grey.shade50,
            ),
            child: Text(
              '--- [ RESERVED 130PX FOR PRE-PRINTED CLINIC LETTERHEAD ] ---',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade500,
                letterSpacing: 1,
              ),
            ),
          )
        else
          _buildDigitalClinicHeader(),
        const SizedBox(height: 14),
        _buildPatientDemographicStrip(),
      ],
    );
  }

  Widget _buildDigitalClinicHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black87, width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GUWAHATIONE CLINIC & DIAGNOSTICS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Outpatient Medical Chamber & Healthcare Services',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                Text(
                  'Guwahati, Assam',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.doctorTitle(consultation.doctorName),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                (doctorSpecialty != null && doctorSpecialty!.trim().isNotEmpty)
                    ? doctorSpecialty!
                    : 'Physician',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
              if (consultation.doctorRegNumber != null &&
                  consultation.doctorRegNumber!.trim().isNotEmpty)
                Text(
                  'Registration No: ${consultation.doctorRegNumber!.trim()}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDemographicStrip() {
    final c = consultation;
    final hasAllergies = patientAllergies.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Patient Name: ${c.patientName}${c.guardianName != null && c.guardianName!.trim().isNotEmpty ? " (c/o ${c.guardianName}${c.guardianRelation != null && c.guardianRelation!.trim().isNotEmpty ? ", ${c.guardianRelation}" : ""})" : ""}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Age / Sex: ${c.patientAgeDisplay ?? (c.patientAge > 0 ? "${c.patientAge} Yrs" : "N/A")} / ${c.patientGender}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Token: #${appointment?.queueNumber.toString().padLeft(2, '0') ?? '01'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Phone: ${c.patientPhone}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Date: ${AppFormatters.dateTime(c.createdAt)}',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Divider(height: 12, thickness: 0.6, color: Colors.black45),

          // Prominent Drug Allergies Callout
          Row(
            children: [
              Text(
                'ALLERGIES: ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: hasAllergies ? Colors.red.shade900 : Colors.black87,
                ),
              ),
              Expanded(
                child: Text(
                  hasAllergies
                      ? patientAllergies.join(', ')
                      : 'No known drug allergies recorded',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasAllergies
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: hasAllergies ? Colors.red.shade900 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Printable clinical snapshot: vitals strip, chief complaints, and provisional diagnosis.
class PrintClinicalSnapshot extends StatelessWidget {
  final Consultation consultation;

  const PrintClinicalSnapshot({super.key, required this.consultation});

  @override
  Widget build(BuildContext context) {
    final c = consultation;
    final vitals = c.vitals;

    final vitalsParts = <String>[];
    if (vitals != null) {
      if (vitals.bpFormatted != null) {
        vitalsParts.add("BP: ${vitals.bpFormatted}");
      }
      if (vitals.pulseRate != null) {
        vitalsParts.add("Pulse: ${vitals.pulseRate} bpm");
      }
      if (vitals.spO2 != null) {
        vitalsParts.add("SpO2: ${vitals.spO2}%");
      }
      if (vitals.temperature != null) {
        vitalsParts.add("Temp: ${vitals.temperature}°F");
      }
      if (vitals.weightKg != null) {
        vitalsParts.add("Weight: ${vitals.weightKg} kg");
      }
    }

    final hasComplaints = c.chiefComplaints.isNotEmpty;
    final hasDiagnosis = c.provisionalDiagnosis.isNotEmpty;
    final hasVitals = vitalsParts.isNotEmpty;

    if (!hasComplaints && !hasDiagnosis && !hasVitals) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasVitals)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "Vitals: ${vitalsParts.join('  |  ')}",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (hasComplaints)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "Chief Complaints: ${c.chiefComplaints.join('; ')}",
                style: const TextStyle(fontSize: 11),
              ),
            ),
          if (hasDiagnosis)
            Text(
              "Diagnosis: ${c.provisionalDiagnosis.join('; ')}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
