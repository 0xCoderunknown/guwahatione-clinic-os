import 'package:flutter/material.dart';

/// Banner displaying patient registration history and doctor-specific review eligibility status.
class BookingEligibilityBanner extends StatelessWidget {
  final String? historyInfo;
  final Color historyColor;
  final bool isNewPatient;

  const BookingEligibilityBanner({
    super.key,
    required this.historyInfo,
    required this.historyColor,
    required this.isNewPatient,
  });

  @override
  Widget build(BuildContext context) {
    if (historyInfo == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: historyColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: historyColor.withValues(alpha: 1.0),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              isNewPatient ? Icons.person_add : Icons.history,
              size: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              historyInfo!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Warning dialog shown when a receptionist selects Free Review after the doctor's
  /// review period has expired or when the doctor has a 0-day (no free review) policy.
  static Future<bool> showReviewWarningDialog(
    BuildContext context, {
    required String doctorName,
    required String dateStr,
    required int days,
    int policyDays = 14,
  }) async {
    final isZeroPolicy = policyDays <= 0;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          isZeroPolicy ? Icons.block_rounded : Icons.warning_amber_rounded,
          color: isZeroPolicy ? Colors.red.shade700 : Colors.amber,
          size: 48,
        ),
        title: Text(
          isZeroPolicy
              ? 'No Free Review Policy'
              : '$policyDays Days Passed Warning',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isZeroPolicy
                  ? '⚠️ Dr. $doctorName does not offer free reviews (0-day policy). Regular consultation fee applies.'
                  : '⚠️ $policyDays days have passed since the patient\'s last visit with Dr. $doctorName.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isZeroPolicy ? Colors.red.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isZeroPolicy
                      ? Colors.red.shade200
                      : Colors.amber.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Last Visit: $dateStr'),
                  Text(
                    isZeroPolicy
                        ? '• Doctor Policy: No Free Review (0 days)'
                        : '• Days Elapsed: $days days (Policy limit: $policyDays days)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isZeroPolicy
                  ? 'This doctor does not offer free reviews. Do you want to override and grant an exception anyway?'
                  : 'Only visits within $policyDays days qualify for free review. Do you want to proceed with a Free Review anyway?',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel (Keep Paid)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isZeroPolicy
                  ? Colors.red.shade700
                  : Colors.amber.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow Free Review'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
