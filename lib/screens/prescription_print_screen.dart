import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment.dart';
import '../models/consultation.dart';
import '../models/prescription_item.dart';
import '../utils/platform_print.dart';

enum PaperSize {
  a4('A4 (Full Sheet)', 820),
  a5('A5 (Compact Pad)', 580);

  final String label;
  final double maxWidth;
  const PaperSize(this.label, this.maxWidth);
}

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
    final activeMeds = c.activePrescriptions;
    final stoppedMeds = c.stoppedPrescriptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Clinic & Doctor Header OR Reserved Letterhead Margin
        if (_usePrePrintedLetterhead)
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

        // 2. Patient Demographic & Allergies Strip
        _buildPatientDemographicStrip(),
        const SizedBox(height: 12),

        // 3. Clinical Snapshot (Vitals, Complaints, Diagnosis)
        _buildClinicalSnapshot(),
        const SizedBox(height: 14),

        // 4. Primary Section: Active Prescriptions Table (Rx)
        _buildActivePrescriptionsSection(activeMeds),
        const SizedBox(height: 14),

        // 5. Audit Section: Discontinued Medications (Strictly Segregated)
        if (stoppedMeds.isNotEmpty) ...[
          _buildDiscontinuedMedicationsSection(stoppedMeds),
          const SizedBox(height: 14),
        ],

        // 6. Diagnostic Orders & Advice
        _buildOrdersAndAdviceSection(),
        const SizedBox(height: 24),

        // 7. Signature & Clinic Stamp Block
        _buildPhysicianSignatureBlock(),
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
                'Dr. ${widget.consultation.doctorName}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                widget.doctorSpecialty ?? 'Consultant Physician',
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
    final c = widget.consultation;
    final hasAllergies = widget.patientAllergies.isNotEmpty;

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
                  'Token: #${widget.appointment?.queueNumber.toString().padLeft(2, '0') ?? '01'}',
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
                  hasAllergies ? widget.patientAllergies.join(', ') : 'Nil Known Drug Allergies',
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

  Widget _buildClinicalSnapshot() {
    final c = widget.consultation;
    final vitals = c.vitals;

    final vitalsParts = <String>[];
    if (vitals != null) {
      if (vitals.bpFormatted != null) vitalsParts.add("BP: ${vitals.bpFormatted}");
      if (vitals.pulseRate != null) vitalsParts.add("Pulse: ${vitals.pulseRate} bpm");
      if (vitals.spO2 != null) vitalsParts.add("SpO2: ${vitals.spO2}%");
      if (vitals.temperature != null) vitalsParts.add("Temp: ${vitals.temperature}°F");
      if (vitals.weightKg != null) vitalsParts.add("Weight: ${vitals.weightKg} kg");
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
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
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

  Widget _buildActivePrescriptionsSection(List<PrescriptionItem> activeMeds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rx Symbol
        const Text(
          '℞  (Active Medication Schedule)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),

        // Active Rx Table
        if (activeMeds.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400, width: 0.6)),
            child: const Center(
              child: Text(
                'No active medications prescribed for this visit.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          Table(
            border: TableBorder.all(color: Colors.black87, width: 0.8),
            columnWidths: const {
              0: FixedColumnWidth(30),
              1: FlexColumnWidth(4.5),
              2: FlexColumnWidth(2.2),
              3: FlexColumnWidth(2.2),
              4: FlexColumnWidth(2.2),
            },
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                    child: Text('Medicine & Composition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text('Dose & Timing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),

              // Item Rows (Strictly START & CONTINUE items)
              ...activeMeds.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;

                final durationLabel = item.durationDays != null
                    ? "${item.durationDays} Days"
                    : "Ongoing (Chronic)";

                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Text('$idx', style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.effectiveName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.action == MedicationAction.continueAction ? '[CONT]' : '[NEW]',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            item.composition,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
                          ),
                          if (item.instructions != null && item.instructions!.isNotEmpty)
                            Text(
                              "Note: ${item.instructions}",
                              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Text("${item.dosage}\n${item.timing}", style: const TextStyle(fontSize: 11)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Text(item.frequency, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Text(durationLabel, style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildDiscontinuedMedicationsSection(List<PrescriptionItem> stoppedMeds) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.black45, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🛑 Discontinued / Stopped Medications This Visit:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          ...stoppedMeds.map((item) {
            final reason = item.stopReason ?? 'Discontinued by physician';
            return Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(
                "• ${item.effectiveName} (${item.composition}) — Reason: $reason",
                style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrdersAndAdviceSection() {
    final c = widget.consultation;
    final hasOrders = c.orderedTests.isNotEmpty;
    final hasAdvice = c.adviceNotes != null && c.adviceNotes!.isNotEmpty;
    final hasFollowUp = c.nextFollowUpDate != null;

    if (!hasOrders && !hasAdvice && !hasFollowUp) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasOrders) ...[
            const Text(
              'Recommended Diagnostic Investigations (For Next Visit):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            const SizedBox(height: 2),
            ...c.orderedTests.map((o) => Text(
                  "• ${o.testName}${o.instructions != null ? ' (${o.instructions})' : ''}",
                  style: const TextStyle(fontSize: 11),
                )),
            const SizedBox(height: 6),
          ],
          if (hasAdvice) ...[
            const Text(
              'Advice & Lifestyle Notes:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(c.adviceNotes!, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 6),
          ],
          if (hasFollowUp)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.grey.shade100,
              child: Text(
                'Next Follow-Up / Review: ${DateFormat('EEEE, dd MMM yyyy').format(c.nextFollowUpDate!)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhysicianSignatureBlock() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinic Seal / Stamp',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            Container(
              width: 120,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black45, width: 0.8)),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 180,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black87, width: 1)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dr. ${widget.consultation.doctorName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Text(
              'Authorized Medical Consultant',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ],
        ),
      ],
    );
  }
}
