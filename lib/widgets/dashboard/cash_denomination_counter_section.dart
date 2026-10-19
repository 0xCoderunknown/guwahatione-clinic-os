import 'package:flutter/material.dart';

import '../../utils/formatters.dart';

/// Interactive denomination counter grid and discrepancy reconciliation badge
/// for daily reception cash handover.
class CashDenominationCounterSection extends StatelessWidget {
  final List<int> denominations;
  final Map<int, int> counts;
  final Map<int, TextEditingController> controllers;
  final int physicalTotal;
  final int discrepancy;
  final void Function(int denom, String val) onCountChanged;
  final VoidCallback onReset;

  const CashDenominationCounterSection({
    super.key,
    required this.denominations,
    required this.counts,
    required this.controllers,
    required this.physicalTotal,
    required this.discrepancy,
    required this.onCountChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                '💵 Physical Cash Drawer Note Counter',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Counts', style: TextStyle(fontSize: 12)),
              onPressed: onReset,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final denom in denominations)
                    SizedBox(
                      width: 190,
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '₹$denom',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('×', style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: TextField(
                                controller: controllers[denom],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) => onCountChanged(denom, val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Reconciliation Result Banner
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Counted Physical Total:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          AppFormatters.currency(physicalTotal),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDiscrepancyBadge(discrepancy),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiscrepancyBadge(int discrepancy) {
    if (discrepancy == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF16A34A)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF15803D),
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              '₹0 Difference • Balanced',
              style: TextStyle(
                color: Color(0xFF15803D),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final isShortage = discrepancy < 0;
    final color = isShortage
        ? const Color(0xFFB91C1C)
        : const Color(0xFFD97706);
    final bgColor = isShortage
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFEF3C7);
    final text = isShortage
        ? 'Shortage: -${AppFormatters.currency(discrepancy.abs())}'
        : 'Surplus: +${AppFormatters.currency(discrepancy)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isShortage
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
