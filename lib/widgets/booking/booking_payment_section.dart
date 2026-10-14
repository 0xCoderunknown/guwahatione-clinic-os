import 'package:flutter/material.dart';

import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../models/patient_review_eligibility.dart';
import '../../utils/app_constants.dart';

/// Form section managing doctor selection, provisional token preview, payment policy, and consultation fees.
/// Supports 100% keyboard navigation and live queue arrival estimation.
class BookingPaymentSection extends StatelessWidget {
  final List<Doctor> doctors;
  final Doctor? selectedDoctor;
  final ValueChanged<Doctor?> onDoctorChanged;
  final PaymentType selectedPayment;
  final ValueChanged<PaymentType?> onPaymentChanged;
  final PatientReviewEligibility reviewEligibility;
  final TextEditingController amountController;
  final FocusNode? doctorFocusNode;
  final FocusNode? paymentFocusNode;
  final FocusNode? amountFocusNode;
  final int? provisionalToken;
  final String? provisionalTimeWindow;
  final int bookedTokensCount;
  final VoidCallback? onSubmitted;

  const BookingPaymentSection({
    super.key,
    required this.doctors,
    required this.selectedDoctor,
    required this.onDoctorChanged,
    required this.selectedPayment,
    required this.onPaymentChanged,
    required this.reviewEligibility,
    required this.amountController,
    this.doctorFocusNode,
    this.paymentFocusNode,
    this.amountFocusNode,
    this.provisionalToken,
    this.provisionalTimeWindow,
    this.bookedTokensCount = 0,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Doctor Picker Dropdown
        DropdownButtonFormField<Doctor>(
          initialValue: selectedDoctor,
          focusNode: doctorFocusNode,
          decoration: const InputDecoration(
            labelText: 'Select Doctor',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_add),
          ),
          items: doctors.map((doc) {
            return DropdownMenuItem(value: doc, child: Text(doc.titleName));
          }).toList(),
          onChanged: onDoctorChanged,
          validator: (val) => val == null ? 'Please select a doctor' : null,
        ),
        if (selectedDoctor != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildTokenCapBadge(
              bookedTokensCount,
              selectedDoctor!.dailyTokenLimit,
            ),
          ),
        ],
        const SizedBox(height: 8),

        // Live Provisional Token & Estimated Wait Time Badge
        _buildProvisionalTokenBadge(),
        const SizedBox(height: 14),

        // 2. Payment Type Dropdown (Ordered: Upfront Paid -> Free Policies -> Unpaid Phone -> Post-Pay at bottom)
        DropdownButtonFormField<PaymentType>(
          key: ValueKey(selectedPayment),
          initialValue: selectedPayment,
          focusNode: paymentFocusNode,
          decoration: const InputDecoration(
            labelText: 'Payment Type',
            border: OutlineInputBorder(),
          ),
          items: const [
            PaymentType.paidCash,
            PaymentType.paidUpi,
            PaymentType.freeReview,
            PaymentType.freeFamily,
            PaymentType.unpaid,
            PaymentType.postPay,
          ].map((type) {
            String label;
            bool enabled = true;
            final fee =
                selectedDoctor?.consultationFee ??
                AppConstants.defaultConsultationFee;
            switch (type) {
              case PaymentType.paidCash:
                label = 'Paid (Cash) — ₹$fee';
                break;
              case PaymentType.paidUpi:
                label = 'Paid (UPI) — ₹$fee';
                break;
              case PaymentType.freeReview:
                if (!reviewEligibility.hasVisitedDoctorEarlier) {
                  enabled = false;
                  label = 'FREE (Review) — Returning patients only';
                } else if (reviewEligibility.isWithinReviewPeriod) {
                  label =
                      'FREE (Review) — Within ${reviewEligibility.allowedReviewDays} days';
                } else {
                  label =
                      'FREE (Review) — ⚠️ >${reviewEligibility.allowedReviewDays} days passed';
                }
                break;
              case PaymentType.freeFamily:
                label = 'Family / Complimentary';
                break;
              case PaymentType.unpaid:
                label = 'Unpaid (Phone Reservation)';
                break;
              case PaymentType.postPay:
                label = 'Post-Pay (Exit Collect — Use with Caution)';
                break;
            }

            return DropdownMenuItem<PaymentType>(
              value: type,
              enabled: enabled,
              child: Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? (type == PaymentType.postPay ? Colors.amber.shade900 : null)
                      : Colors.grey.shade500,
                  fontWeight: type == PaymentType.postPay ? FontWeight.w600 : null,
                ),
              ),
            );
          }).toList(),
          onChanged: onPaymentChanged,
        ),

        // Cautionary banner when Post-Pay is chosen
        if (selectedPayment == PaymentType.postPay) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFB45309),
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Caution: Fee will NOT be collected upfront at reception. Patient must return to counter to pay after consultation.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Warning banner if Free Review is selected when allowed review period has passed
        if (selectedPayment == PaymentType.freeReview &&
            reviewEligibility.hasVisitedDoctorEarlier &&
            !reviewEligibility.isWithinReviewPeriod) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber.shade900,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Warning: ${reviewEligibility.allowedReviewDays} days have passed (${reviewEligibility.daysSinceLastVisit} days since last visit). Free review manually approved.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),

        // 3. Amount Input Field (Locks to ₹0 on Free Review)
        TextFormField(
          controller: amountController,
          focusNode: amountFocusNode,
          readOnly: selectedPayment == PaymentType.freeReview,
          decoration: InputDecoration(
            labelText: 'Amount (₹)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.currency_rupee),
            filled: selectedPayment == PaymentType.freeReview,
            fillColor: selectedPayment == PaymentType.freeReview
                ? Colors.grey.shade100
                : null,
            helperText: selectedPayment == PaymentType.freeReview
                ? 'No fee · Eligible free follow-up'
                : null,
          ),
          keyboardType: TextInputType.number,
          validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
          onFieldSubmitted: (_) => onSubmitted?.call(),
        ),
      ],
    );
  }

  Widget _buildProvisionalTokenBadge() {
    if (selectedDoctor == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Select a doctor to preview token & wait time',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final token = provisionalToken ?? 1;
    final timeStr = provisionalTimeWindow ?? 'Now';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Emerald / teal soft tint
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '🎟️ Next Token: #$token • Est. Time: $timeStr',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCapBadge(int booked, int limit) {
    final status = AppointmentEngine.evaluateTokenCapStatus(
      bookedCount: booked,
      limit: limit,
    );

    Color bgColor;
    Color fgColor;
    Border? border;
    String text;

    switch (status) {
      case TokenCapStatus.normal:
        bgColor = const Color(0xFFF1F5F9);
        fgColor = const Color(0xFF475569);
        border = Border.all(color: const Color(0xFFCBD5E1));
        text = '$booked/$limit Booked';
        break;
      case TokenCapStatus.runwayAlert:
        bgColor = const Color(0xFFFEF3C7);
        fgColor = const Color(0xFFB45309);
        border = Border.all(color: const Color(0xFFFCD34D));
        final left = limit - booked;
        text = '⚠️ $booked/$limit Booked • $left Left';
        break;
      case TokenCapStatus.atLimit:
        bgColor = const Color(0xFFFFEDD5);
        fgColor = const Color(0xFFC2410C);
        border = Border.all(color: const Color(0xFFFDBA74));
        text = '⚠️ $booked/$limit Full';
        break;
      case TokenCapStatus.overCap:
        bgColor = const Color(0xFFFEF2F2);
        fgColor = const Color(0xFFB91C1C);
        border = Border.all(color: const Color(0xFFEF4444), width: 1.2);
        text = '🔴 $booked/$limit • Extra Token';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fgColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
