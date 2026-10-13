import 'package:flutter/material.dart';

import '../../core/engines/engines.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_print.dart';

/// Modal dialog for reception staff and clinic owners to perform
/// end-of-day financial reconciliation, note denomination counting, and cash handover.
class DailyCashHandoverDialog extends StatefulWidget {
  final ClinicProvider provider;

  const DailyCashHandoverDialog({super.key, required this.provider});

  static Future<void> show(BuildContext context, ClinicProvider provider) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DailyCashHandoverDialog(provider: provider),
    );
  }

  @override
  State<DailyCashHandoverDialog> createState() =>
      _DailyCashHandoverDialogState();
}

class _DailyCashHandoverDialogState extends State<DailyCashHandoverDialog> {
  // Common Indian Currency Denominations
  final List<int> _denominations = const [500, 200, 100, 50, 20, 10];
  final Map<int, int> _counts = {500: 0, 200: 0, 100: 0, 50: 0, 20: 0, 10: 0};

  late final Map<int, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final d in _denominations) d: TextEditingController(text: '0'),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onCountChanged(int denom, String val) {
    final parsed = int.tryParse(val) ?? 0;
    setState(() {
      _counts[denom] = parsed >= 0 ? parsed : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final summary = CashHandoverEngine.calculateCashHandover(
      appointments: widget.provider.todayAppointments,
      date: now,
    );

    final physicalTotal = CashHandoverEngine.calculateDenominationTotal(
      _counts,
    );
    final discrepancy = CashHandoverEngine.calculateDiscrepancy(
      physicalCounted: physicalTotal,
      expectedCash: summary.totalRealizedCash,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Cash Handover & Closing Reconciliation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '🗓️ ${AppFormatters.dateWithDay(now)} • Reception Shift Closing',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // KPI Strip
                    Row(
                      children: [
                        _buildSummaryCard(
                          title: 'Expected Cash',
                          value: AppFormatters.currency(
                            summary.totalRealizedCash,
                          ),
                          color: const Color(0xFF047857),
                          bgColor: const Color(0xFFECFDF5),
                          icon: Icons.payments_rounded,
                        ),
                        const SizedBox(width: 12),
                        _buildSummaryCard(
                          title: 'Completed OPD',
                          value: '${summary.totalCompleted} Patients',
                          color: const Color(0xFF0F766E),
                          bgColor: const Color(0xFFF0FDFA),
                          icon: Icons.people_alt_rounded,
                        ),
                        const SizedBox(width: 12),
                        _buildSummaryCard(
                          title: 'Paid / Free',
                          value:
                              '${summary.totalPaidCount} / ${summary.totalFreeReviewCount + summary.totalFreeFamilyCount}',
                          color: const Color(0xFF6B21A8),
                          bgColor: const Color(0xFFFAF5FF),
                          icon: Icons.pie_chart_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Doctor Breakdown Table
                    const Text(
                      '👨‍⚕️ Doctor-Wise Consultation & Cash Breakdown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: summary.doctorBreakdown.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No doctor consultations recorded today.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : Table(
                              border: TableBorder.symmetric(
                                inside: const BorderSide(
                                  color: Color(0xFFF1F5F9),
                                ),
                              ),
                              columnWidths: const {
                                0: FlexColumnWidth(3),
                                1: FlexColumnWidth(1.2),
                                2: FlexColumnWidth(1.5),
                                3: FlexColumnWidth(1.5),
                                4: FlexColumnWidth(2),
                              },
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                  ),
                                  children: [
                                    _buildTh('Doctor'),
                                    _buildTh('OPD'),
                                    _buildTh('Paid'),
                                    _buildTh('Free'),
                                    _buildTh('Cash Collected'),
                                  ],
                                ),
                                for (final row in summary.doctorBreakdown)
                                  TableRow(
                                    children: [
                                      _buildTd(row.doctorName, isBold: true),
                                      _buildTd('${row.completedCount}'),
                                      _buildTd('${row.paidCount}'),
                                      _buildTd(
                                        '${row.freeReviewCount + row.freeFamilyCount}',
                                      ),
                                      _buildTd(
                                        AppFormatters.currency(
                                          row.cashCollected,
                                        ),
                                        isBold: true,
                                        color: const Color(0xFF047857),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Physical Denomination Calculator Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '💵 Physical Cash Drawer Note Counter',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text(
                            'Reset Counts',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            setState(() {
                              for (final d in _denominations) {
                                _counts[d] = 0;
                                _controllers[d]!.text = '0';
                              }
                            });
                          },
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
                              for (final denom in _denominations)
                                SizedBox(
                                  width: 190,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 54,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                      const Text(
                                        '×',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SizedBox(
                                          height: 36,
                                          child: TextField(
                                            controller: _controllers[denom],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            decoration: const InputDecoration(
                                              contentPadding: EdgeInsets.zero,
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            onChanged: (val) =>
                                                _onCountChanged(denom, val),
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
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
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Print Handover Slip'),
                    onPressed: () => printDocument(),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildTh(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildTd(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? const Color(0xFF0F172A),
        ),
      ),
    );
  }
}
