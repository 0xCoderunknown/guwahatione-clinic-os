import 'package:flutter/material.dart';

import '../../models/medicine.dart';
import '../../models/prescription_item.dart';
import '../../utils/medicine_search_scorer.dart';
import '../common/section_card.dart';
import 'encounter_form_state.dart';
import 'rx/reconciliation_item_row.dart';
import 'rx/rx_search_results_view.dart';
import 'rx/staged_medicine_form.dart';

/// Step 4: Medication Reconciliation & Prescribing Section Coordinator
class RxReconciliationSection extends StatelessWidget {
  final EncounterFormState form;
  final List<Medicine> catalog;
  final String Function() uuidGenerator;
  final void Function(PrescriptionItem item, int index) onPromptStopReason;
  final VoidCallback onUpdate;

  const RxReconciliationSection({
    super.key,
    required this.form,
    required this.catalog,
    required this.uuidGenerator,
    required this.onPromptStopReason,
    required this.onUpdate,
  });

  const RxReconciliationSection.fromForm({
    super.key,
    required this.form,
    required this.catalog,
    required this.uuidGenerator,
    required this.onPromptStopReason,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final searchResults = form.medSearchController.text.trim().isNotEmpty
        ? MedicineSearchScorer.searchAndGroup(
            catalog: catalog,
            query: form.medSearchController.text,
            searchMode: form.searchMode,
          )
        : const <CompositionGroupResult>[];

    return SectionCard(
      title: 'Step 4: Medication Prescribing & Reconciliation',
      icon: Icons.medication_rounded,
      isExpanded: form.isMedicineExpanded,
      onToggleExpand: () {
        form.isMedicineExpanded = !form.isMedicineExpanded;
        onUpdate();
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchModePill('brandFirst', '🏷️ Brand'),
                _buildSearchModePill('compositionFirst', '🧪 Salt'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: Icon(form.isMedicineExpanded ? Icons.unfold_less : Icons.unfold_more, size: 18),
            label: Text(form.isMedicineExpanded ? 'Close Medicine' : 'Open Medicine'),
            onPressed: () {
              form.isMedicineExpanded = !form.isMedicineExpanded;
              onUpdate();
            },
          ),
        ],
      ),
      child: form.isMedicineExpanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (form.reconciliationItems.isNotEmpty) ...[
                  ReconciliationListCard(
                    items: form.reconciliationItems,
                    onContinue: (idx) {
                      form.reconciliationItems[idx] = form.reconciliationItems[idx].copyWith(
                        action: MedicationAction.continueAction,
                        stopReason: null,
                      );
                      onUpdate();
                    },
                    onPromptStop: onPromptStopReason,
                  ),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'Add Medicine (Search by Brand or Composition)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: form.medSearchController,
                  decoration: InputDecoration(
                    hintText: form.searchMode == 'brandFirst'
                        ? 'Type brand name (e.g., Telma, Dolo, Augmentin, Pan)...'
                        : 'Type composition / salt (e.g., Telmisartan, Paracetamol)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: form.medSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              form.medSearchController.clear();
                              form.isSearchActive = false;
                              onUpdate();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    form.isSearchActive = val.trim().isNotEmpty;
                    onUpdate();
                  },
                ),
                const SizedBox(height: 8),

                if (form.isSearchActive && form.medSearchController.text.trim().isNotEmpty) ...[
                  RxSearchResultsView(
                    results: searchResults,
                    query: form.medSearchController.text,
                    onStageGeneric: (grp) {
                      form.stageGeneric(grp, uuidGenerator);
                      onUpdate();
                    },
                    onStageMedicine: (med) {
                      form.stageMedicine(med);
                      onUpdate();
                    },
                    onStageUnlisted: (query) {
                      form.stageUnlisted(query);
                      onUpdate();
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                if (form.stagedMedicine != null ||
                    form.stagedGenericGroup != null ||
                    form.stagedUnlistedName != null) ...[
                  StagedMedicineForm.fromForm(
                    form: form,
                    uuidGenerator: uuidGenerator,
                    onUpdate: onUpdate,
                  ),
                  const SizedBox(height: 14),
                ],

                NewPrescriptionsList(
                  items: form.newPrescriptions,
                  onRemove: (idx) {
                    form.newPrescriptions.removeAt(idx);
                    onUpdate();
                  },
                ),

                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal.shade50,
                      foregroundColor: Colors.teal.shade800,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Close Medicine & Proceed to Tests'),
                    onPressed: () {
                      form.isMedicineExpanded = !form.isMedicineExpanded;
                      onUpdate();
                    },
                  ),
                ),
              ],
            )
          : CollapsedMedicineSummary(
              continuedCount: form.reconciliationItems.where((i) => i.action == MedicationAction.continueAction).length,
              stoppedCount: form.reconciliationItems.where((i) => i.action == MedicationAction.stop).length,
              newCount: form.newPrescriptions.length,
              onTap: () {
                form.isMedicineExpanded = !form.isMedicineExpanded;
                onUpdate();
              },
            ),
    );
  }

  Widget _buildSearchModePill(String mode, String label) {
    final isSelected = form.searchMode == mode;
    return InkWell(
      onTap: () {
        form.searchMode = mode;
        onUpdate();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.teal.shade800 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
