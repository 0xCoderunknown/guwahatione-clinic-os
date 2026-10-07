import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/diagnostic_investigation.dart';
import '../../models/prescription_item.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';

/// Modal dialogs and sheets used during a clinical consultation encounter.
class EncounterDialogs {
  const EncounterDialogs._();

  /// Dialog to add a new documented allergy for the patient.
  static Future<void> promptAddAllergy(
    BuildContext context,
    ValueChanged<String> onAdd,
  ) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Allergy'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Allergen / Drug Name',
            hintText: 'e.g., Penicillin, Sulfa, NSAIDs, Peanuts...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                onAdd(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Dialog to document an outside lab test/investigation.
  static Future<void> promptAddOutsideLabReview(
    BuildContext context,
    String Function() uuidGenerator,
    ValueChanged<DiagnosticInvestigationReview> onAdd,
  ) async {
    final nameCtrl = TextEditingController();
    final resultCtrl = TextEditingController();
    DateTime pickedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Outside Lab Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Test Name',
                hintText: 'e.g., HbA1c, Lipid Profile, Ultrasound...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resultCtrl,
              decoration: const InputDecoration(
                labelText: 'Findings / Result Value',
                hintText: 'e.g., 6.8%, Normal sinus rhythm...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                onAdd(
                  DiagnosticInvestigationReview(
                    id: uuidGenerator(),
                    testName: name,
                    resultValue: resultCtrl.text.trim(),
                    performedDate: pickedDate,
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Dialog to capture explicit clinical reason for discontinuing a drug.
  static Future<void> promptStopReason(
    BuildContext context,
    PrescriptionItem item,
    ValueChanged<String> onConfirmStop,
  ) async {
    final reasonCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Stop ${item.effectiveName}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select or type the clinical reason for discontinuing this drug:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: ['Condition Resolved', 'Adverse Effect / Intolerance', 'Ineffective', 'Switched']
                  .map((chip) => ActionChip(
                        label: Text(chip, style: const TextStyle(fontSize: 11)),
                        onPressed: () => reasonCtrl.text = chip,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Stop Reason (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              final reason = reasonCtrl.text.trim().isEmpty ? 'Discontinued by Doctor' : reasonCtrl.text.trim();
              onConfirmStop(reason);
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Stop'),
          ),
        ],
      ),
    );
  }

  /// Dialog to enter prior chronic medications from outside records.
  static Future<void> openPriorMedicationHistoryDialog(
    BuildContext context,
    String Function() uuidGenerator,
    ValueChanged<PrescriptionItem> onAdd,
  ) async {
    final medCtrl = TextEditingController();
    final doseCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prior Outside Regimen Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add outside medications that a new patient was already taking prior to this encounter. These will be added as ongoing baseline medications.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: medCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Medication Name & Strength',
                hintText: 'e.g., Metformin 500mg, Telmisartan 40mg...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: doseCtrl,
              decoration: const InputDecoration(
                labelText: 'Schedule / Frequency',
                hintText: 'e.g., Once daily morning after food',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = medCtrl.text.trim();
              if (val.isNotEmpty) {
                onAdd(
                  PrescriptionItem(
                    id: uuidGenerator(),
                    action: MedicationAction.continueAction,
                    medicineName: val,
                    composition: val,
                    dosage: '1 Dose',
                    frequency: doseCtrl.text.trim().isNotEmpty ? doseCtrl.text.trim() : 'Once daily',
                    timing: 'After Food',
                    durationDays: null, // baseline chronic
                    unlistedName: val,
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add to Baseline'),
          ),
        ],
      ),
    );
  }

  /// Date picker for next follow up visit.
  static Future<DateTime?> pickCustomFollowUpDate(
    BuildContext context, {
    DateTime? currentDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  /// Bottom sheet showing longitudinal consultation history.
  static Future<void> showLongitudinalHistory(
    BuildContext context, {
    required String patientPhone,
  }) async {
    final clinic = Provider.of<ClinicProvider>(context, listen: false);
    final history = await clinic.getPatientConsultations(patientPhone);

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    "Longitudinal Record (${history.length} visits)",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: history.isEmpty
                  ? const Center(child: Text('No previous consultation records for this patient.'))
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 12),
                      itemBuilder: (c, i) {
                        final record = history[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppFormatters.dateTime(record.createdAt),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    "Dr. ${record.doctorName}",
                                    style: TextStyle(fontSize: 12, color: Colors.teal.shade800),
                                  ),
                                ],
                              ),
                              if (record.vitals?.bpFormatted != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text("BP: ${record.vitals!.bpFormatted}", style: const TextStyle(fontSize: 12)),
                                ),
                              if (record.provisionalDiagnosis.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Diagnosis: ${record.provisionalDiagnosis.join(', ')}",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                "Rx: ${record.activePrescriptions.map((p) => p.effectiveName).join(', ')}",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
