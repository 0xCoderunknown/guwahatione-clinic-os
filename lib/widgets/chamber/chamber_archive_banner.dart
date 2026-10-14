import 'package:flutter/material.dart';

/// Read-Only Archive Banner displayed in Doctor Chamber when viewing historical dates.
///
/// Informs the physician that past records are immutable and read-only.
class ChamberArchiveBanner extends StatelessWidget {
  final DateTime? date;

  const ChamberArchiveBanner({super.key, this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Soft slate
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      alignment: Alignment.center,
      child: const Text(
        '🔒 Viewing Past Records (Read-Only)',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Color(0xFF475569),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
