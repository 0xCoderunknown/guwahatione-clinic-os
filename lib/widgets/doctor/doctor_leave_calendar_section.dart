import 'package:flutter/material.dart';

import '../../utils/formatters.dart';

/// Interactive UI card for clinic owners to configure planned doctor leave dates (single days or date ranges).
class DoctorLeaveCalendarSection extends StatelessWidget {
  final List<DateTime> blockedDates;
  final ValueChanged<List<DateTime>> onDatesChanged;

  const DoctorLeaveCalendarSection({
    super.key,
    required this.blockedDates,
    required this.onDatesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 20,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Planned Leave & Blocked Dates',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F766E),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () => _pickSingleLeaveDate(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              'Add Day',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () => _pickLeaveDateRange(context),
                            icon: const Icon(Icons.date_range, size: 16),
                            label: const Text(
                              'Add Week / Range',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  const Icon(
                    Icons.event_busy,
                    size: 20,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Planned Leave & Blocked Dates',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => _pickSingleLeaveDate(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Add Day',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => _pickLeaveDateRange(context),
                    icon: const Icon(Icons.date_range, size: 16),
                    label: const Text(
                      'Add Week / Range',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          const Text(
            'Mark individual days or extended week leave. The reception desk will strictly block bookings on these dates.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          if (blockedDates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No planned leaves configured.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: blockedDates.map((d) {
                return Chip(
                  avatar: const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Color(0xFF991B1B),
                  ),
                  label: Text(
                    AppFormatters.date(d),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  backgroundColor: const Color(0xFFFEE2E2),
                  deleteIcon: const Icon(
                    Icons.close,
                    size: 14,
                    color: Color(0xFF991B1B),
                  ),
                  onDeleted: () {
                    final updated = List<DateTime>.from(blockedDates)..remove(d);
                    onDatesChanged(updated);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _pickSingleLeaveDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Select Doctor Leave Date',
    );
    if (picked != null) {
      final normalized = DateTime(picked.year, picked.month, picked.day);
      if (!blockedDates.any(
        (d) =>
            d.year == normalized.year &&
            d.month == normalized.month &&
            d.day == normalized.day,
      )) {
        final updated = List<DateTime>.from(blockedDates)..add(normalized);
        updated.sort((a, b) => a.compareTo(b));
        onDatesChanged(updated);
      }
    }
  }

  Future<void> _pickLeaveDateRange(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Select Doctor Leave Date Range',
    );
    if (picked != null) {
      final updated = List<DateTime>.from(blockedDates);
      for (
        var d = picked.start;
        !d.isAfter(picked.end);
        d = d.add(const Duration(days: 1))
      ) {
        final nd = DateTime(d.year, d.month, d.day);
        if (!updated.any(
          (x) => x.year == nd.year && x.month == nd.month && x.day == nd.day,
        )) {
          updated.add(nd);
        }
      }
      updated.sort((a, b) => a.compareTo(b));
      onDatesChanged(updated);
    }
  }
}
