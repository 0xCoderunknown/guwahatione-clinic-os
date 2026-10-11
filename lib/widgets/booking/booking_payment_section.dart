import 'package:flutter/material.dart';

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
            return DropdownMenuItem(value: doc, child: Text(doc.name));
          }).toList(),
          onChanged: onDoctorChanged,
          validator: (val) => val == null ? 'Please select a doctor' : null,
        ),
        const SizedBox(height: 8),

        // Live Provisional Token & Estimated Wait Time Badge
        _buildProvisionalTokenBadge(),
        const SizedBox(height: 14),

        // 2. Payment Type Dropdown
        DropdownButtonFormField<PaymentType>(
          key: ValueKey(selectedPayment),
          initialValue: selectedPayment,
          focusNode: paymentFocusNode,
          decoration: const InputDecoration(
            labelText: 'Payment Type',
            border: OutlineInputBorder(),
          ),
          items: PaymentType.values.map((type) {
            String label;
            bool enabled = true;
            if (type == PaymentType.paid) {
              final fee =
                  selectedDoctor?.consultationFee ??
                  AppConstants.defaultConsultationFee;
              label = 'Paid (₹$fee)';
            } else if (type == PaymentType.freeFamily) {
              label = 'FREE (Family)';
            } else {
              // PaymentType.freeReview
              if (!reviewEligibility.hasVisitedDoctorEarlier) {
                enabled = false;
                label = 'FREE (Review) — Returning patients only';
              } else if (reviewEligibility.isWithin14Days) {
                label = 'FREE (Review) — Within 14 days';
              } else {
                label = 'FREE (Review) — ⚠️ >14 days passed';
              }
            }

            return DropdownMenuItem<PaymentType>(
              value: type,
              enabled: enabled,
              child: Text(
                label,
                style: TextStyle(color: enabled ? null : Colors.grey.shade500),
              ),
            );
          }).toList(),
          onChanged: onPaymentChanged,
        ),

        // Warning banner if Free Review is selected when >14 days has passed
        if (selectedPayment == PaymentType.freeReview &&
            reviewEligibility.hasVisitedDoctorEarlier &&
            !reviewEligibility.isWithin14Days) ...[
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
                    'Warning: 14 days have passed (${reviewEligibility.daysSinceLastVisit} days since last visit). Free review manually approved.',
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
                ? 'Locked to ₹0 for 14-day Free Review'
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
}
