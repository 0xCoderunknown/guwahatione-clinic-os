import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../utils/formatters.dart';

/// Standardized payment indicator badge for OPD reception ledger.
class PaymentBadge extends StatelessWidget {
  final PaymentType paymentType;
  final num? amount;
  final bool isCompact;

  const PaymentBadge({
    super.key,
    required this.paymentType,
    this.amount,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    String label;
    IconData icon;

    switch (paymentType) {
      case PaymentType.paidCash:
        bg = const Color(0xFFECFDF5);
        textColor = const Color(0xFF065F46);
        final amtStr = amount != null && amount! > 0
            ? AppFormatters.currency(amount)
            : 'Paid (Cash)';
        label = amtStr.startsWith('₹') ? '$amtStr (Cash)' : amtStr;
        icon = Icons.payments_rounded;
        break;
      case PaymentType.paidUpi:
        bg = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF1D4ED8);
        final amtStr = amount != null && amount! > 0
            ? AppFormatters.currency(amount)
            : 'Paid (UPI)';
        label = amtStr.startsWith('₹') ? '$amtStr (UPI)' : amtStr;
        icon = Icons.qr_code_2_rounded;
        break;
      case PaymentType.paidCarryOver:
        bg = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF15803D);
        final amtStr = amount != null && amount! > 0
            ? AppFormatters.currency(amount)
            : 'Prepaid';
        label = '$amtStr (Carry-Over)';
        icon = Icons.replay_circle_filled_rounded;
        break;
      case PaymentType.freeReview:
        bg = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF15803D);
        label = 'Free Review (14d)';
        icon = Icons.verified_outlined;
        break;
      case PaymentType.freeFamily:
        bg = const Color(0xFFEDE9FE);
        textColor = const Color(0xFF6D28D9);
        label = 'Courtesy / Family';
        icon = Icons.favorite_outline_rounded;
        break;
      case PaymentType.postPay:
        bg = const Color(0xFFFFFBEB);
        textColor = const Color(0xFFB45309);
        label = 'Post-Pay (Exit)';
        icon = Icons.hourglass_bottom_rounded;
        break;
      case PaymentType.unpaid:
        bg = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFDC2626);
        label = 'Unpaid';
        icon = Icons.pending_actions_rounded;
        break;
    }

    final verticalPadding = isCompact ? 2.0 : 4.0;
    final horizontalPadding = isCompact ? 6.0 : 8.0;
    final fontSize = isCompact ? 10.0 : 11.0;
    final iconSize = isCompact ? 11.0 : 13.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
