import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/appointment.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';

/// 1-Tap Desk Reconciliation Modal for Receptionists.
/// Allows checking in an advance/phone-booked patient into the physical lobby,
/// recording the payment method (Cash, UPI, Post-Pay, Free Review, or Free Family),
/// and immediately enabling doctor chamber calling.
class QuickCheckInDialog extends StatefulWidget {
  final Appointment appointment;

  const QuickCheckInDialog({super.key, required this.appointment});

  static Future<bool?> show(
    BuildContext context, {
    required Appointment appointment,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => QuickCheckInDialog(appointment: appointment),
    );
  }

  @override
  State<QuickCheckInDialog> createState() => _QuickCheckInDialogState();
}

class _QuickCheckInDialogState extends State<QuickCheckInDialog> {
  late final TextEditingController _customAmountController;
  bool _isLoading = false;
  late int _defaultFee;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ClinicProvider>(context, listen: false);
    final doctor = provider.getDoctorById(widget.appointment.doctorId);
    _defaultFee =
        doctor?.consultationFee ??
        (widget.appointment.amountCollected > 0
            ? widget.appointment.amountCollected
            : 500);
    _customAmountController = TextEditingController(text: '$_defaultFee');
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _processCheckIn(PaymentType paymentType, int amount) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<ClinicProvider>(context, listen: false);
      await provider.checkInPatient(
        appointmentId: widget.appointment.id,
        paymentType: paymentType,
        amountCollected: amount,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Checked in Token #${widget.appointment.queueNumber} (${widget.appointment.patientName}) into Lobby • ${paymentType.displayName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check in patient: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsedFee =
        int.tryParse(_customAmountController.text.trim()) ?? _defaultFee;
    final isFreeReviewEligible =
        widget.appointment.paymentType == PaymentType.freeReview;
    final isFreeFamily =
        widget.appointment.paymentType == PaymentType.freeFamily;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1): () =>
            _processCheckIn(PaymentType.paidCash, parsedFee),
        const SingleActivator(LogicalKeyboardKey.digit2): () =>
            _processCheckIn(PaymentType.paidUpi, parsedFee),
        const SingleActivator(LogicalKeyboardKey.digit3): () =>
            _processCheckIn(PaymentType.postPay, 0),
        const SingleActivator(LogicalKeyboardKey.digit4): () {
          if (isFreeReviewEligible) _processCheckIn(PaymentType.freeReview, 0);
        },
        const SingleActivator(LogicalKeyboardKey.digit5): () =>
            _processCheckIn(PaymentType.freeFamily, 0),
      },
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.how_to_reg_rounded,
                  color: Color(0xFF0F766E),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lobby Check-In • Token #${widget.appointment.queueNumber}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${widget.appointment.patientName} (${widget.appointment.patientPhone})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assigned: ${AppFormatters.doctorTitle(widget.appointment.doctorName)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Standard Fee: ₹$_defaultFee',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Payment & Admit to Lobby (1-Tap):',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 10),

                // Primary Payment Options
                _buildActionTile(
                  keyLabel: '1',
                  icon: Icons.payments_rounded,
                  title: 'Collect Cash',
                  subtitle: 'Paid in cash at desk',
                  amountBadge: '₹$parsedFee',
                  color: const Color(0xFF15803D),
                  bgColor: const Color(0xFFDCFCE7),
                  onTap: () => _processCheckIn(PaymentType.paidCash, parsedFee),
                ),
                const SizedBox(height: 8),

                _buildActionTile(
                  keyLabel: '2',
                  icon: Icons.qr_code_2_rounded,
                  title: 'Collect UPI',
                  subtitle: 'Paid via clinic QR code',
                  amountBadge: '₹$parsedFee',
                  color: const Color(0xFF1D4ED8),
                  bgColor: const Color(0xFFDBEAFE),
                  onTap: () => _processCheckIn(PaymentType.paidUpi, parsedFee),
                ),
                const SizedBox(height: 8),

                _buildActionTile(
                  keyLabel: '3',
                  icon: Icons.hourglass_bottom_rounded,
                  title: 'Post-Pay (Pay on Exit)',
                  subtitle: 'Patient will settle fee after consultation',
                  amountBadge: '₹0 now',
                  color: const Color(0xFFB45309),
                  bgColor: const Color(0xFFFEF3C7),
                  onTap: () => _processCheckIn(PaymentType.postPay, 0),
                ),
                const SizedBox(height: 8),

                if (isFreeReviewEligible) ...[
                  _buildActionTile(
                    keyLabel: '4',
                    icon: Icons.verified_rounded,
                    title: 'Free Review (14-Day Statutory)',
                    subtitle: 'Returning within 14 days of last paid visit',
                    amountBadge: '₹0 (Locked)',
                    color: const Color(0xFF0F766E),
                    bgColor: const Color(0xFFCCFBF1),
                    onTap: () => _processCheckIn(PaymentType.freeReview, 0),
                  ),
                  const SizedBox(height: 8),
                ],

                _buildActionTile(
                  keyLabel: isFreeReviewEligible ? '5' : '4',
                  icon: Icons.favorite_rounded,
                  title: 'FREE (Family / VVIP Waiver)',
                  subtitle: isFreeFamily
                      ? 'Pre-authorized discretionary clinic waiver'
                      : 'Discretionary clinic waiver (Locked at ₹0)',
                  amountBadge: '₹0 (Waiver)',
                  color: const Color(0xFF7E22CE),
                  bgColor: const Color(0xFFF3E8FF),
                  onTap: () => _processCheckIn(PaymentType.freeFamily, 0),
                ),

                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String keyLabel,
    required IconData icon,
    required String title,
    required String subtitle,
    required String amountBadge,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Text(
                  keyLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  amountBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
