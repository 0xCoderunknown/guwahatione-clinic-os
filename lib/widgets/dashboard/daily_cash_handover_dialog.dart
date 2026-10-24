import 'package:flutter/material.dart';

import '../../core/engines/engines.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_print.dart';
import 'cash_denomination_counter_section.dart';

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
      expectedCash: summary.totalPhysicalCash,
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
                    // KPI Strip (Segregated Cash, UPI & Grand Total)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final card1 = _buildSummaryCard(
                          title: 'Physical Cash',
                          value: AppFormatters.currency(
                            summary.totalPhysicalCash,
                          ),
                          color: const Color(0xFF047857),
                          bgColor: const Color(0xFFECFDF5),
                          icon: Icons.payments_rounded,
                        );
                        final card2 = _buildSummaryCard(
                          title: 'UPI (Bank)',
                          value: AppFormatters.currency(
                            summary.totalUpiRevenue,
                          ),
                          color: const Color(0xFF0284C7),
                          bgColor: const Color(0xFFF0F9FF),
                          icon: Icons.account_balance_rounded,
                        );
                        final card3 = _buildSummaryCard(
                          title: 'Total Revenue',
                          value: AppFormatters.currency(summary.totalRevenue),
                          color: const Color(0xFF4F46E5),
                          bgColor: const Color(0xFFEEF2FF),
                          icon: Icons.account_balance_wallet_rounded,
                        );
                        final card4 = _buildSummaryCard(
                          title: 'Completed OPD',
                          value: '${summary.totalCompleted} Patients',
                          color: const Color(0xFF0F766E),
                          bgColor: const Color(0xFFF0FDFA),
                          icon: Icons.people_alt_rounded,
                        );

                        if (constraints.maxWidth < 560) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: card1),
                                  const SizedBox(width: 10),
                                  Expanded(child: card2),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: card3),
                                  const SizedBox(width: 10),
                                  Expanded(child: card4),
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: card1),
                            const SizedBox(width: 10),
                            Expanded(child: card2),
                            const SizedBox(width: 10),
                            Expanded(child: card3),
                            const SizedBox(width: 10),
                            Expanded(child: card4),
                          ],
                        );
                      },
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
                                0: FlexColumnWidth(2.5),
                                1: FlexColumnWidth(1.0),
                                2: FlexColumnWidth(1.5),
                                3: FlexColumnWidth(1.5),
                                4: FlexColumnWidth(1.5),
                              },
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                  ),
                                  children: [
                                    _buildTh('Doctor'),
                                    _buildTh('OPD'),
                                    _buildTh('Cash'),
                                    _buildTh('UPI'),
                                    _buildTh('Total'),
                                  ],
                                ),
                                for (final row in summary.doctorBreakdown)
                                  TableRow(
                                    children: [
                                      _buildTd(row.doctorName, isBold: true),
                                      _buildTd('${row.completedCount}'),
                                      _buildTd(
                                        AppFormatters.currency(
                                          row.cashCollected,
                                        ),
                                        color: const Color(0xFF047857),
                                      ),
                                      _buildTd(
                                        AppFormatters.currency(
                                          row.upiCollected,
                                        ),
                                        color: const Color(0xFF0284C7),
                                      ),
                                      _buildTd(
                                        AppFormatters.currency(
                                          row.totalRevenue,
                                        ),
                                        isBold: true,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Physical Denomination Calculator Section
                    CashDenominationCounterSection(
                      denominations: _denominations,
                      counts: _counts,
                      controllers: _controllers,
                      physicalTotal: physicalTotal,
                      discrepancy: discrepancy,
                      onCountChanged: _onCountChanged,
                      onReset: () {
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
    return Container(
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
