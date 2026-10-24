import 'package:flutter/material.dart';

import '../../config/clinic_config.dart';
import '../../core/engines/engines.dart';
import '../../models/medicine.dart';
import '../../models/prescription_item.dart';
import '../../utils/formatters.dart';
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
    final isQueryLongEnough =
        searchQuery.length >= 3 ||
        (searchQuery.length == 2 && RegExp(r'\d').hasMatch(searchQuery));
    final searchResults = isQueryLongEnough
        ? MedicineEngine.searchAndGroup(catalog: catalog, query: searchQuery)
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
                if (form.reconciliationItems.isEmpty &&
                    form.pastConsultations.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      final lastRx = form.lastConsultationWithRx;
                      if (lastRx == null) return const SizedBox.shrink();

                      final count = lastRx.activePrescriptions.length;
                      final d = lastRx.createdAt;
                      final dateStr = AppFormatters.date(d);
                      final daysAgo = DateTime.now().difference(d).inDays;
                      final daysStr = daysAgo == 0
                          ? 'today'
                          : (daysAgo == 1 ? 'yesterday' : '$daysAgo days ago');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.teal.shade300,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history_edu_rounded,
                                size: 20,
                                color: Colors.teal.shade700,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Prior Regimen Found: $count active medication${count > 1 ? 's' : ''} (Last visit: $dateStr • $daysStr)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal.shade900,
                                  ),
                                ),
                              ),
                              FilledButton.tonalIcon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: Text(
                                  'CARRY FORWARD ($count)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  form.carryForwardFromConsultation(
                                    consultation: lastRx,
                                    uuidGenerator: uuidGenerator,
                                  );
                                  onUpdate();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],

                if (form.reconciliationItems.isNotEmpty) ...[
                  ReconciliationListCard(
                    items: form.reconciliationItems,
                    priorConsultation: form.lastConsultationWithRx,
                    onContinue: (idx) {
                      form.reconciliationItems[idx] = form
                          .reconciliationItems[idx]
                          .copyWith(
                            action: MedicationAction.continueAction,
                            stopReason: null,
                          );
                      onUpdate();
                    },
                    onStop: (idx) {
                      form.reconciliationItems[idx] = form
                          .reconciliationItems[idx]
                          .copyWith(
                            action: MedicationAction.stop,
                            stopReason: 'Discontinued by doctor',
                          );
                      onUpdate();
                    },
                    onItemUpdated: (idx, updated) {
                      form.reconciliationItems[idx] = updated;
                      onUpdate();
                    },
                    onPromptStop: onPromptStopReason,
                  ),
                  const SizedBox(height: 14),
                ],

                Builder(
                  builder: (context) {
                    final lastRx = form.lastConsultationWithRx;
                    if (lastRx == null) return const SizedBox.shrink();

                    final reconciledNames = form.reconciliationItems
                        .map((r) => r.effectiveName.trim().toLowerCase())
                        .toSet();
                    final acuteCompleted = lastRx.activePrescriptions
                        .where(
                          (p) =>
                              !p.isChronic &&
                              !reconciledNames.contains(
                                p.effectiveName.trim().toLowerCase(),
                              ),
                        )
                        .toList();

                    if (acuteCompleted.isEmpty) return const SizedBox.shrink();

                    final d = lastRx.createdAt;
                    final dateStr = AppFormatters.date(d);
                    final daysAgo = DateTime.now().difference(d).inDays;
                    final daysStr = daysAgo == 0
                        ? 'today'
                        : (daysAgo == 1 ? 'yesterday' : '$daysAgo days ago');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                size: 15,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Prior Completed Course(s) • Last visit: $dateStr ($daysStr)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...acuteCompleted.map((acute) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '• ${acute.effectiveName} [${acute.composition.toUpperCase()}] — ${acute.formattedDosageTiming} — ${acute.effectiveDuration}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.replay_rounded,
                                      size: 13,
                                    ),
                                    label: const Text(
                                      'Repeat Course',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    onPressed: () {
                                      form.reconciliationItems.add(
                                        acute.copyWith(
                                          id: uuidGenerator(),
                                          action: MedicationAction.continueAction,
                                          stopReason: null,
                                        ),
                                      );
                                      onUpdate();
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),

                if (activeConfig
                    .features
                    .enablePrescriptionTemplatePresets) ...[
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
                  focusNode: form.medSearchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Type medicine name or composition (min 3 letters, e.g., Tel, Dolo, Pan)...',
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
                  onItemUpdated: (idx, updated) {
                    form.newPrescriptions[idx] = updated;
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
