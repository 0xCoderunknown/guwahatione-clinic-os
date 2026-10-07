import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../models/patient_review_eligibility.dart';
import '../../utils/app_constants.dart';

/// Form section managing doctor selection, payment type (paid/free review/free family), and consultation fees.
class BookingPaymentSection extends StatelessWidget {
  final List<Doctor> doctors;
  final Doctor? selectedDoctor;
  final ValueChanged<Doctor?> onDoctorChanged;
  final PaymentType selectedPayment;
  final ValueChanged<PaymentType?> onPaymentChanged;
  final PatientReviewEligibility reviewEligibility;
  final TextEditingController amountController;

  const BookingPaymentSection({
    super.key,
    required this.doctors,
    required this.selectedDoctor,
    required this.onDoctorChanged,
    required this.selectedPayment,
    required this.onPaymentChanged,
    required this.reviewEligibility,
    required this.amountController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Doctor Picker Dropdown
        DropdownButtonFormField<Doctor>(
          initialValue: selectedDoctor,
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
        const SizedBox(height: 16),

        // Payment Type Dropdown
        DropdownButtonFormField<PaymentType>(
          key: ValueKey(selectedPayment),
          initialValue: selectedPayment,
          decoration: const InputDecoration(
            labelText: 'Payment Type',
            border: OutlineInputBorder(),
          ),
          items: PaymentType.values.map((type) {
            String label;
            bool enabled = true;
            if (type == PaymentType.paid) {
              final fee = selectedDoctor?.consultationFee ??
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
                style: TextStyle(
                  color: enabled ? null : Colors.grey.shade500,
                ),
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
        const SizedBox(height: 16),

        // Amount Input Field
        TextFormField(
          controller: amountController,
          decoration: const InputDecoration(
            labelText: 'Amount (₹)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.currency_rupee),
          ),
          keyboardType: TextInputType.number,
          validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }
}
