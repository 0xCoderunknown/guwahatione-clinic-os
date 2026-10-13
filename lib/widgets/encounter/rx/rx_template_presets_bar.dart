import 'package:flutter/material.dart';

import '../../../core/engines/engines.dart';
import '../../../models/prescription_template.dart';
import '../encounter_form_state.dart';

/// 1-tap horizontal preset bar for common OPD medication bundles.
class RxTemplatePresetsBar extends StatelessWidget {
  final EncounterFormState form;
  final String Function() uuidGenerator;
  final VoidCallback onUpdate;
  final List<PrescriptionTemplate>? customTemplates;

  const RxTemplatePresetsBar({
    super.key,
    required this.form,
    required this.uuidGenerator,
    required this.onUpdate,
    this.customTemplates,
  });

  @override
  Widget build(BuildContext context) {
    final templates =
        customTemplates ?? MedicineEngine.getDefaultPrescriptionTemplates();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bolt_rounded,
              size: 16,
              color: Color(0xFF0F766E), // teal-700
            ),
            const SizedBox(width: 4),
            const Text(
              '1-Tap OPD Presets',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155), // slate-700
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(Common acute bundles • skips duplicates)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: templates.map((tmpl) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                child: Tooltip(
                  message: '${tmpl.name}: ${tmpl.description}',
                  child: ActionChip(
                    avatar: Text(
                      tmpl.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    label: Text(
                      tmpl.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    backgroundColor: const Color(0xFFF0FDFA), // teal-50
                    side: const BorderSide(
                      color: Color(0xFF99F6E4), // teal-200
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    elevation: 0,
                    pressElevation: 1,
                    onPressed: () {
                      final result = form.applyPrescriptionTemplate(
                        template: tmpl,
                        uuidGenerator: uuidGenerator,
                      );
                      onUpdate();

                      _showFeedback(context, result);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showFeedback(BuildContext context, TemplateApplicationResult result) {
    String msg;
    Color bg = const Color(0xFF0F766E); // teal-700

    if (result.addedItems.isNotEmpty && result.skippedDuplicates.isEmpty) {
      msg = 'Applied "${result.templateName}" (+${result.addedItems.length} meds)';
    } else if (result.addedItems.isNotEmpty && result.skippedDuplicates.isNotEmpty) {
      msg = 'Applied "${result.templateName}" (+${result.addedItems.length} meds, ${result.skippedDuplicates.length} duplicate skipped)';
    } else {
      msg = 'All medications from "${result.templateName}" are already active';
      bg = Colors.amber.shade900;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: bg,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
