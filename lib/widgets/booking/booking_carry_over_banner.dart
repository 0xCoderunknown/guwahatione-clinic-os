import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../utils/formatters.dart';

/// Informational banner alerting reception to an eligible prepaid un-consulted appointment
/// from a prior date that can be carried over with ₹0 fresh cash collection (QOL-03).
class BookingCarryOverBanner extends StatelessWidget {
  final Appointment eligibleAppointment;
  final bool isApplied;
  final VoidCallback onApply;
  final VoidCallback onUndo;

  const BookingCarryOverBanner({
    super.key,
    required this.eligibleAppointment,
    required this.isApplied,
    required this.onApply,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = AppFormatters.date(eligibleAppointment.scheduledDate);
    final docTitle = AppFormatters.doctorTitle(eligibleAppointment.doctorName);
    final amount = eligibleAppointment.amountCollected > 0
        ? eligibleAppointment.amountCollected
        : (eligibleAppointment.carriedOverAmount ?? 0);

    if (isApplied) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Prepaid Carry-Over Applied',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onUndo,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: const Color(0xFFDC2626),
                  ),
                  child: const Text('Undo', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Linked to Token #${eligibleAppointment.queueNumber} from $dateStr (₹$amount paid). '
              '₹0 fresh cash collected at desk today. Doctor payout will be credited upon consultation completion.',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF14532D),
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.replay_circle_filled_rounded,
                color: Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Prepaid Carry-Over Available',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
              FilledButton.tonal(
                onPressed: onApply,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFDE68A),
                  foregroundColor: const Color(0xFF78350F),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Apply (₹0 Today)'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Patient paid ₹$amount to $docTitle on $dateStr (Token #${eligibleAppointment.queueNumber}) '
            'but was unattended. Revalidate for today with ₹0 fresh collection?',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF78350F),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
