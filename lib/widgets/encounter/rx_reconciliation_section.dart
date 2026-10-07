import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../models/prescription_item.dart';
import '../../utils/medicine_search_scorer.dart';
import '../common/section_card.dart';
import 'encounter_form_state.dart';

/// Step 4: Medication Reconciliation & Prescribing Section
class RxReconciliationSection extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  // Search Mode & Query
  final String searchMode;
  final ValueChanged<String> onSearchModeChanged;
  final TextEditingController medSearchController;
  final bool isSearchActive;
  final List<CompositionGroupResult> searchResults;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  // Reconciliation Baseline (Prior Visits)
  final List<PrescriptionItem> reconciliationItems;
  final void Function(int index) onContinueItem;
  final void Function(PrescriptionItem item, int index) onPromptStopReason;

  // Staged Medicine
  final Medicine? stagedMedicine;
  final CompositionGroupResult? stagedGenericGroup;
  final String? stagedUnlistedName;
  final String? stagedComposition;
  final TextEditingController stagedDosageController;
  final TextEditingController stagedDurationController;
  final TextEditingController stagedInstructionsController;
  final String stagedFrequency;
  final ValueChanged<String?> onFrequencyChanged;
  final String stagedTiming;
  final ValueChanged<String?> onTimingChanged;
  final bool stagedIsChronic;
  final ValueChanged<bool> onChronicChanged;
  final VoidCallback onCancelStaging;
  final VoidCallback onConfirmAddStaged;

  // Triggering Staging
  final ValueChanged<Medicine> onStageMedicine;
  final ValueChanged<CompositionGroupResult> onStageGeneric;
  final ValueChanged<String> onStageUnlisted;

  // New Prescriptions (Current Encounter)
  final List<PrescriptionItem> newPrescriptions;
  final ValueChanged<int> onRemoveNewPrescription;

  const RxReconciliationSection({
    super.key,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.searchMode,
    required this.onSearchModeChanged,
    required this.medSearchController,
    required this.isSearchActive,
    required this.searchResults,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.reconciliationItems,
    required this.onContinueItem,
    required this.onPromptStopReason,
    required this.stagedMedicine,
    required this.stagedGenericGroup,
    required this.stagedUnlistedName,
    required this.stagedComposition,
    required this.stagedDosageController,
    required this.stagedDurationController,
    required this.stagedInstructionsController,
    required this.stagedFrequency,
    required this.onFrequencyChanged,
    required this.stagedTiming,
    required this.onTimingChanged,
    required this.stagedIsChronic,
    required this.onChronicChanged,
    required this.onCancelStaging,
    required this.onConfirmAddStaged,
    required this.onStageMedicine,
    required this.onStageGeneric,
    required this.onStageUnlisted,
    required this.newPrescriptions,
    required this.onRemoveNewPrescription,
  });

  /// Factory binding directly to EncounterFormState.
  RxReconciliationSection.fromForm({
    super.key,
    required EncounterFormState form,
    required List<Medicine> catalog,
    required String Function() uuidGenerator,
    required this.onPromptStopReason,
    required VoidCallback onUpdate,
  })  : isExpanded = form.isMedicineExpanded,
        onToggleExpand = (() {
          form.isMedicineExpanded = !form.isMedicineExpanded;
          onUpdate();
        }),
        searchMode = form.searchMode,
        onSearchModeChanged = ((mode) {
          form.searchMode = mode;
          onUpdate();
        }),
        medSearchController = form.medSearchController,
        isSearchActive = form.isSearchActive,
        searchResults = form.medSearchController.text.trim().isNotEmpty
            ? MedicineSearchScorer.searchAndGroup(
                catalog: catalog,
                query: form.medSearchController.text,
                searchMode: form.searchMode,
              )
            : <CompositionGroupResult>[],
        onSearchChanged = ((val) {
          form.isSearchActive = val.trim().isNotEmpty;
          onUpdate();
        }),
        onClearSearch = (() {
          form.medSearchController.clear();
          form.isSearchActive = false;
          onUpdate();
        }),
        reconciliationItems = form.reconciliationItems,
        onContinueItem = ((index) {
          form.reconciliationItems[index] = form.reconciliationItems[index].copyWith(
            action: MedicationAction.continueAction,
            stopReason: null,
          );
          onUpdate();
        }),
        stagedMedicine = form.stagedMedicine,
        stagedGenericGroup = form.stagedGenericGroup,
        stagedUnlistedName = form.stagedUnlistedName,
        stagedComposition = form.stagedComposition,
        stagedDosageController = form.stagedDosageController,
        stagedDurationController = form.stagedDurationController,
        stagedInstructionsController = form.stagedInstructionsController,
        stagedFrequency = form.stagedFrequency,
        onFrequencyChanged = ((val) {
          if (val != null) {
            form.stagedFrequency = val;
            onUpdate();
          }
        }),
        stagedTiming = form.stagedTiming,
        onTimingChanged = ((val) {
          if (val != null) {
            form.stagedTiming = val;
            onUpdate();
          }
        }),
        stagedIsChronic = form.stagedIsChronic,
        onChronicChanged = ((val) {
          form.stagedIsChronic = val;
          onUpdate();
        }),
        onCancelStaging = (() {
          form.cancelStaging();
          onUpdate();
        }),
        onConfirmAddStaged = (() {
          form.confirmAddStagedMedicine(uuidGenerator);
          onUpdate();
        }),
        onStageMedicine = ((med) {
          form.stageMedicine(med);
          onUpdate();
        }),
        onStageGeneric = ((grp) {
          form.stageGeneric(grp, uuidGenerator);
          onUpdate();
        }),
        onStageUnlisted = ((query) {
          form.stageUnlisted(query);
          onUpdate();
        }),
        newPrescriptions = form.newPrescriptions,
        onRemoveNewPrescription = ((index) {
          form.newPrescriptions.removeAt(index);
          onUpdate();
        });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Step 4: Medication Prescribing & Reconciliation',
      icon: Icons.medication_rounded,
      isExpanded: isExpanded,
      onToggleExpand: onToggleExpand,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search mode toggle pill
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
            icon: Icon(isExpanded ? Icons.unfold_less : Icons.unfold_more, size: 18),
            label: Text(isExpanded ? 'Close Medicine' : 'Open Medicine'),
            onPressed: onToggleExpand,
          ),
        ],
      ),
      child: isExpanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section A: Past Active Meds (Reconciliation Baseline)
                if (reconciliationItems.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.published_with_changes_rounded, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              "Medication Reconciliation (From Prior Visits)",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                            ),
                            const Spacer(),
                            Text(
                              "${reconciliationItems.length} active previously",
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reconciliationItems.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                          itemBuilder: (ctx, index) {
                            return _buildReconciliationItemRow(reconciliationItems[index], index);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Section B: INLINE Rapid Medicine Prescribing
                const Text(
                  'Add Medicine (Search by Brand or Composition)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: medSearchController,
                  decoration: InputDecoration(
                    hintText: searchMode == 'brandFirst'
                        ? 'Type brand name (e.g., Telma, Dolo, Augmentin, Pan)...'
                        : 'Type composition / salt (e.g., Telmisartan, Paracetamol)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: medSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: onClearSearch,
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: onSearchChanged,
                ),
                const SizedBox(height: 8),

                // Live Autocomplete Suggestions
                if (isSearchActive && medSearchController.text.trim().isNotEmpty) ...[
                  _buildInlineSearchResults(searchResults),
                  const SizedBox(height: 12),
                ],

                // Staged Medicine Form with Prefilled Defaults
                if (stagedMedicine != null || stagedGenericGroup != null || stagedUnlistedName != null) ...[
                  _buildStagedMedicineForm(),
                  const SizedBox(height: 14),
                ],

                // List of newly prescribed medications
                const Text(
                  'Prescribed Medications (This Encounter)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                if (newPrescriptions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Text(
                        'No new medicines added yet. Type in search bar above to prescribe.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: newPrescriptions.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                    itemBuilder: (ctx, index) {
                      return _buildNewPrescriptionRow(newPrescriptions[index], index);
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
                    onPressed: onToggleExpand,
                  ),
                ),
              ],
            )
          : _buildCollapsedMedicineSummary(),
    );
  }

  Widget _buildSearchModePill(String mode, String label) {
    final isSelected = searchMode == mode;
    return InkWell(
      onTap: () => onSearchModeChanged(mode),
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

  Widget _buildReconciliationItemRow(PrescriptionItem item, int index) {
    final isContinued = item.action == MedicationAction.continueAction;
    final isStopped = item.action == MedicationAction.stop;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isStopped ? Colors.red.shade50.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isContinued
              ? Colors.teal.shade300
              : isStopped
                  ? Colors.red.shade300
                  : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.effectiveName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: isStopped ? TextDecoration.lineThrough : null,
                    color: isStopped ? Colors.grey : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "${item.composition} • ${item.dosage} • ${item.frequency} • ${item.timing}${item.durationDays != null ? ' (${item.durationDays}d)' : ' (Chronic)'}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (isStopped && item.stopReason != null && item.stopReason!.isNotEmpty)
                  Text(
                    "Stopped Reason: ${item.stopReason}",
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 1-Tap CONTINUE Button
          ChoiceChip(
            label: const Text('CONTINUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            selected: isContinued,
            selectedColor: Colors.teal.shade100,
            onSelected: (val) {
              if (val) onContinueItem(index);
            },
          ),
          const SizedBox(width: 6),

          // 1-Tap STOP Button
          ChoiceChip(
            label: const Text('STOP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            selected: isStopped,
            selectedColor: Colors.red.shade100,
            onSelected: (val) {
              if (val) onPromptStopReason(item, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInlineSearchResults(List<CompositionGroupResult> results) {
    final query = medSearchController.text.trim();

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        children: [
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'No matching medicine found for "$query".',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () => onStageUnlisted(query),
                    child: Text('Prescribe Outside: "$query"'),
                  ),
                ],
              ),
            )
          else ...[
            ...results.take(6).map((group) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${group.compositionLabel} [${group.form}]",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                          ),
                        ),
                        InkWell(
                          onTap: () => onStageGeneric(group),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: Text(
                              '+ Prescribe Generic',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: group.associatedBrands.map((brand) {
                        return ActionChip(
                          avatar: const Icon(Icons.local_pharmacy_outlined, size: 14, color: Colors.teal),
                          label: Text(
                            "${brand.productName}${brand.manufacturer != null ? ' (${brand.manufacturer})' : ''}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.teal.shade200),
                          onPressed: () => onStageMedicine(brand),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 12),
            InkWell(
              onTap: () => onStageUnlisted(query),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Prescribe unlisted outside brand: "$query"',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStagedMedicineForm() {
    String displayName = '';
    String compName = stagedComposition ?? '';
    if (stagedMedicine != null) {
      displayName = stagedMedicine!.productName;
      if (compName.isEmpty) compName = stagedMedicine!.fullCompositionLabel;
    } else if (stagedGenericGroup != null) {
      displayName = stagedGenericGroup!.compositionLabel;
      if (compName.isEmpty) compName = 'Generic formulation';
    } else if (stagedUnlistedName != null) {
      displayName = stagedUnlistedName!;
      if (compName.isEmpty) compName = 'Outside / Unlisted';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, size: 18, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Staging: $displayName ($compName)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Cancel Staging',
                onPressed: onCancelStaging,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: stagedDosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: '1 Tablet / 5 ml',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: stagedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    '1-0-0 (OD)',
                    '1-0-1 (BD)',
                    '0-0-1 (HS)',
                    '1-1-1 (TDS)',
                    'SOS (As Needed)',
                    'Once Weekly',
                  ].map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: onFrequencyChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: stagedTiming,
                  decoration: const InputDecoration(
                    labelText: 'Timing',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'After Food',
                    'Before Food',
                    'After Food (Morning)',
                    'At Bedtime',
                    'With Food',
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: onTimingChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: stagedDurationController,
                  enabled: !stagedIsChronic,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: stagedIsChronic ? 'Duration' : 'Days',
                    hintText: stagedIsChronic ? 'Continuous' : '30',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text('Continuous (Chronic)', style: TextStyle(fontSize: 11)),
                selected: stagedIsChronic,
                onSelected: onChronicChanged,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: stagedInstructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions / Notes (Optional)',
                    hintText: 'e.g., Take with warm water...',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: onCancelStaging,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add to Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: onConfirmAddStaged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPrescriptionRow(PrescriptionItem item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              'START',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.effectiveName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${item.composition} • ${item.dosage} • ${item.frequency} • ${item.timing} • ${item.durationDays != null ? '${item.durationDays} days' : 'Chronic'}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (item.instructions != null && item.instructions!.isNotEmpty)
                  Text(
                    "Note: ${item.instructions}",
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
            onPressed: () => onRemoveNewPrescription(index),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedMedicineSummary() {
    final continuedCount = reconciliationItems
        .where((i) => i.action == MedicationAction.continueAction)
        .length;
    final stoppedCount = reconciliationItems
        .where((i) => i.action == MedicationAction.stop)
        .length;
    final newCount = newPrescriptions.length;

    return InkWell(
      onTap: onToggleExpand,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(Icons.medication_rounded, size: 18, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Rx Schedule: $newCount new prescribed • $continuedCount continued • $stoppedCount stopped',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              'Tap to expand',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
