import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/consultation.dart';
import '../utils/platform_print.dart';
import '../widgets/widgets.dart';

enum PaperSize {
  a4('A4 (Full Sheet)', 820),
  a5('A5 (Compact Pad)', 580);

  final String label;
  final double maxWidth;
  const PaperSize(this.label, this.maxWidth);
}

/// Prescription Print Preview and Print Coordinator Screen.
class PrescriptionPrintScreen extends StatefulWidget {
  final Consultation consultation;
  final Appointment? appointment;
  final List<String> patientAllergies;
  final String? doctorSpecialty;

  const PrescriptionPrintScreen({
    super.key,
    required this.consultation,
    this.appointment,
    this.patientAllergies = const [],
    this.doctorSpecialty,
  });

  @override
  State<PrescriptionPrintScreen> createState() => _PrescriptionPrintScreenState();
}

class _PrescriptionPrintScreenState extends State<PrescriptionPrintScreen> {
  bool _usePrePrintedLetterhead = false;
  PaperSize _paperSize = PaperSize.a4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: const Text('Prescription Print Preview'),
        elevation: 0.5,
        backgroundColor: Colors.white,
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Print Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => printDocument(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Toolbar: Letterhead toggle & Paper size selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                // Pre-printed Letterhead Toggle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description_outlined, size: 18, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text(
                      'Pre-Printed Letterhead Mode:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _usePrePrintedLetterhead,
                      activeThumbColor: Colors.teal,
                      onChanged: (val) {
                        setState(() {
                          _usePrePrintedLetterhead = val;
                        });
                      },
                    ),
                    Text(
                      _usePrePrintedLetterhead ? 'ON (Margin reserved)' : 'OFF (Digital header)',
                      style: TextStyle(
                        fontSize: 12,
                        color: _usePrePrintedLetterhead ? Colors.teal.shade800 : Colors.grey.shade600,
                        fontWeight: _usePrePrintedLetterhead ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),

                // Paper Size Selection
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Paper Size: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    SegmentedButton<PaperSize>(
                      segments: PaperSize.values
                          .map((p) => ButtonSegment(value: p, label: Text(p.label, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      selected: {_paperSize},
                      onSelectionChanged: (set) {
                        setState(() {
                          _paperSize = set.first;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Scrollable Printable Sheet
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _paperSize.maxWidth),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                    child: _buildPrintableDocument(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintableDocument() {
    final c = widget.consultation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Digital Clinic Header OR Reserved Letterhead Margin + Patient Demographic Strip
        PrintHeaderAndDemographics(
          consultation: c,
          appointment: widget.appointment,
          patientAllergies: widget.patientAllergies,
          doctorSpecialty: widget.doctorSpecialty,
          usePrePrintedLetterhead: _usePrePrintedLetterhead,
        ),
        const SizedBox(height: 12),

        // 2. Clinical Snapshot (Vitals, Complaints, Diagnosis)
        PrintClinicalSnapshot(consultation: c),
        const SizedBox(height: 14),

        // 3. Primary Rx Schedule Table & Discontinued Audit Box
        PrintMedicationsTable(
          activeMeds: c.activePrescriptions,
          stoppedMeds: c.stoppedPrescriptions,
        ),
        const SizedBox(height: 14),

        // 4. Diagnostic Orders, Advice & Physician Signature Block
        PrintOrdersAndFooter(consultation: c),
      ],
    );
  }
}
