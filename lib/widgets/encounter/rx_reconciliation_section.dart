import 'package:flutter/material.dart';

import '../../config/clinic_config.dart';
import '../../core/engines/engines.dart';
import '../../models/medicine.dart';
import '../../models/prescription_item.dart';
import '../common/section_card.dart';
import 'encounter_form_state.dart';
import 'rx/reconciliation_item_row.dart';
import 'rx/rx_search_results_view.dart';
import 'rx/rx_template_presets_bar.dart';
import 'rx/staged_medicine_form.dart';

/// Step 4: Medication Reconciliation & Prescribing Section Coordinator
class RxReconciliationSection extends StatelessWidget {
  final EncounterFormState form;
  final List<Medicine> catalog;
  final String Function() uuidGenerator;
  final void Function(PrescriptionItem item, int index) onPromptStopReason;
  final VoidCallback onUpdate;
  final ClinicConfig? config;

  const RxReconciliationSection({
    super.key,
    required this.form,
    required this.catalog,
    required this.uuidGenerator,
    required this.onPromptStopReason,
    required this.onUpdate,
    this.config,
  });

  const RxReconciliationSection.fromForm({
    super.key,
    required this.form,
    required this.catalog,
    required this.uuidGenerator,
    required this.onPromptStopReason,
    required this.onUpdate,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final activeConfig = config ?? ClinicConfig.current;
    final searchQuery = form.medSearchController.text.trim();
    final isQueryLongEnough = searchQuery.length >= 3 ||
        (searchQuery.length == 2 && RegExp(r'\d').hasMatch(searchQuery));
    final searchResults = isQueryLongEnough
        ? MedicineEngine.searchAndGroup(
            catalog: catalog,
            query: searchQuery,
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
          if (MediaQuery.sizeOf(context).width >= 600) ...[
            TextButton.icon(
              icon: Icon(
                form.isMedicineExpanded ? Icons.unfold_less : Icons.unfold_more,
                size: 18,
              ),
              label: Text(
                form.isMedicineExpanded ? 'Close Medicine' : 'Open Medicine',
              ),
              onPressed: () {
                form.isMedicineExpanded = !form.isMedicineExpanded;
                onUpdate();
              },
            ),
          ],
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
                      form.reconciliationItems[idx] = form
                          .reconciliationItems[idx]
                          .copyWith(
                            action: MedicationAction.continueAction,
                            stopReason: null,
                          );
                      onUpdate();
                    },
                    onPromptStop: onPromptStopReason,
                  ),
                  const SizedBox(height: 16),
                ],

                if (activeConfig.features.enablePrescriptionTemplatePresets) ...[
                  RxTemplatePresetsBar(
                    form: form,
                    uuidGenerator: uuidGenerator,
                    onUpdate: onUpdate,
                  ),
                  const SizedBox(height: 14),
                ],

                const Text(
                  'Add Medicine (Search by Brand or Composition)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: form.medSearchController,
                  decoration: InputDecoration(
                    hintText:
                        'Type medicine name or composition (min 3 letters, e.g., Tel, Dolo, Pan)...',
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    form.isSearchActive = val.trim().isNotEmpty;
                    onUpdate();
                  },
                ),
                if (searchQuery.isNotEmpty && !isQueryLongEnough) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.blueGrey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Type at least 3 letters to search medicines (e.g., Tel, Dol, Pan)...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                if (form.isSearchActive && isQueryLongEnough) ...[
                  RxSearchResultsView(
                    results: searchResults,
                    query: searchQuery,
                    enableGroupedCompositionCards:
                        activeConfig.features.enableGroupedCompositionCards,
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
          : Builder(
              builder: (context) {
                final partition = MedicineEngine.segregatePrescriptions(
                  form.reconciliationItems,
                );
                return CollapsedMedicineSummary(
                  continuedCount: partition.continuedMeds.length,
                  stoppedCount: partition.stoppedMeds.length,
                  newCount: form.newPrescriptions.length,
                  onTap: () {
                    form.isMedicineExpanded = !form.isMedicineExpanded;
                    onUpdate();
                  },
                );
              },
            ),
    );
  }
}
