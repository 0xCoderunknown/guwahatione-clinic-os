import 'package:flutter/material.dart';

/// Bottom persistent docking bar for saving and signing consultation encounter.
class ConsultationBottomDock extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onCompleteAndSign;

  const ConsultationBottomDock({
    super.key,
    required this.isSaving,
    required this.onCancel,
    required this.onCompleteAndSign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: isSaving ? null : onCancel,
            child: const Text('Cancel / Back'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(
              isSaving ? 'Saving & Ending...' : 'CONSULTATION END (Save & Sign)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: isSaving ? null : onCompleteAndSign,
          ),
        ],
      ),
    );
  }
}
