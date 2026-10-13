import 'package:flutter/material.dart';

import '../../utils/formatters.dart';

/// Read-Only Archive Banner displayed in Doctor Chamber when viewing historical dates.
///
/// Disables live chamber controls (Ready, Next Patient, Emergency Door Call)
/// and informs the physician that past records are immutable and read-only.
class ChamberArchiveBanner extends StatelessWidget {
  final DateTime date;

  const ChamberArchiveBanner({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Soft slate
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF94A3B8)),
            ),
            child: const Icon(
              Icons.lock_clock_rounded,
              color: Color(0xFF475569),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🔒 Chamber Shift Closed • Read-Only Archive',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Viewing historical OPD records for ${AppFormatters.date(date)}. Live calling and patient admission are disabled.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
