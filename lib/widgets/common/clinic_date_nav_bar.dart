import 'package:flutter/material.dart';

import '../../utils/formatters.dart';

/// Reusable Date Navigation Bar with Previous / Next day arrows and calendar picker.
class ClinicDateNavBar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback? onTodayPressed;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const ClinicDateNavBar({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.onTodayPressed,
    this.firstDate,
    this.lastDate,
  });

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  bool get _canGoBack {
    if (firstDate == null) return true;
    final prevDay = selectedDate.subtract(const Duration(days: 1));
    final prevStart = DateTime(prevDay.year, prevDay.month, prevDay.day);
    final firstStart = DateTime(firstDate!.year, firstDate!.month, firstDate!.day);
    return !prevStart.isBefore(firstStart);
  }

  bool get _canGoForward {
    if (lastDate == null) return true;
    final nextDay = selectedDate.add(const Duration(days: 1));
    final nextStart = DateTime(nextDay.year, nextDay.month, nextDay.day);
    final lastStart = DateTime(lastDate!.year, lastDate!.month, lastDate!.day);
    return !nextStart.isAfter(lastStart);
  }

  void _pickDate(BuildContext context) async {
    final effectiveFirst = firstDate ?? DateTime(2020);
    final effectiveLast = lastDate ?? DateTime(2030);
    final clampedInitial = selectedDate.isBefore(effectiveFirst)
        ? effectiveFirst
        : (selectedDate.isAfter(effectiveLast) ? effectiveLast : selectedDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: clampedInitial,
      firstDate: effectiveFirst,
      lastDate: effectiveLast,
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }

  void _stepDays(int days) {
    onDateChanged(selectedDate.add(Duration(days: days)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            tooltip: 'Previous Day',
            visualDensity: VisualDensity.compact,
            onPressed: _canGoBack ? () => _stepDays(-1) : null,
          ),
          InkWell(
            onTap: () => _pickDate(context),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Color(0xFF0F766E),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isToday
                        ? 'Today (${AppFormatters.date(selectedDate)})'
                        : AppFormatters.dateWithDay(selectedDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            tooltip: 'Next Day',
            visualDensity: VisualDensity.compact,
            onPressed: _canGoForward ? () => _stepDays(1) : null,
          ),
          if (!_isToday) ...[
            const SizedBox(width: 6),
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () {
                if (onTodayPressed != null) {
                  onTodayPressed!();
                } else {
                  final now = DateTime.now();
                  onDateChanged(DateTime(now.year, now.month, now.day));
                }
              },
              child: const Text(
                'Today',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
