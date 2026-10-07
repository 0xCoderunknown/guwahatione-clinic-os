import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/appointment.dart';
import '../../models/consultation.dart';

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
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
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
                  'Guwahati, Assam • Ph: +91 98765 43210 • Reg: CL-OPD-7821',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Dr. ${consultation.doctorName}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                doctorSpecialty ?? 'Consultant Physician',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
              Text(
                'Registration No: MCI-ASSAM-2014-982',
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
                  'Patient Name: ${c.patientName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Age / Sex: ${c.patientAge > 0 ? c.patientAge : "N/A"} Yrs / ${c.patientGender}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Token: #${appointment?.queueNumber.toString().padLeft(2, '0') ?? '01'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                  'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(c.createdAt)}',
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
                  hasAllergies ? patientAllergies.join(', ') : 'Nil Known Drug Allergies',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasAllergies ? FontWeight.bold : FontWeight.normal,
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
