import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/clinic_config.dart';
import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';
import '../booking/booking_eligibility_banner.dart';
import '../booking/quick_check_in_dialog.dart';
import '../common/appointment_status_chip.dart';
import '../common/payment_badge.dart';
import '../common/token_badge.dart';
import '../print/token_receipt_dialog.dart';
import 'accordion_dispatch_section.dart';
import 'accordion_status_actions.dart';

/// Accordion card for reception appointment queue management.
///
/// Supports single-expansion accordion mode, prominent [SEND IN] chamber dispatch,
/// visual indicators for active in-chamber or bypassed patients, and protective
/// confirmation guards before overriding an occupied doctor chamber or marking absent.
class AppointmentAccordion extends StatefulWidget {
  final Appointment appointment;
  final bool? isExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final bool isInChamber;
  final bool showDoctorTag;

  const AppointmentAccordion({
    super.key,
    required this.appointment,
    this.isExpanded,
    this.onExpansionChanged,
    this.isInChamber = false,
    this.showDoctorTag = false,
  });

  @override
  State<AppointmentAccordion> createState() => _AppointmentAccordionState();
}

class _AppointmentAccordionState extends State<AppointmentAccordion> {
  late PaymentType _selectedPaymentType;
  final ExpansibleController _tileController = ExpansibleController();

  @override
  void initState() {
    super.initState();
    _selectedPaymentType = widget.appointment.paymentType;
  }

  @override
  void didUpdateWidget(covariant AppointmentAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appointment.paymentType != widget.appointment.paymentType) {
      _selectedPaymentType = widget.appointment.paymentType;
    }

    if (widget.isExpanded != null &&
        widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded! && !_tileController.isExpanded) {
        _tileController.expand();
      } else if (!widget.isExpanded! && _tileController.isExpanded) {
        _tileController.collapse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Card styling based on queue state
    Color cardBg = Colors.white;
    BorderSide cardBorder = BorderSide.none;

    if (widget.isInChamber) {
      cardBg = const Color(0xFFF0FDF4); // Green 50
      cardBorder = const BorderSide(color: Color(0xFF16A34A), width: 1.5);
    } else if (widget.appointment.isPaused) {
      cardBg = const Color(0xFFFAF5FF); // Purple 50
      cardBorder = const BorderSide(color: Color(0xFFD8B4FE), width: 1.2);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: cardBorder,
      ),
      child: ExpansionTile(
        controller: _tileController,
        initiallyExpanded: widget.isExpanded ?? false,
        onExpansionChanged: (expanded) {
          if (expanded) {
            _selectedPaymentType = widget.appointment.paymentType;
          }
          widget.onExpansionChanged?.call(expanded);
        },
        leading: TokenBadge(
          queueNumber: widget.appointment.queueNumber,
          doctorTag: widget.showDoctorTag
              ? AppFormatters.doctorInitials(widget.appointment.doctorName)
              : null,
          isCompleted: widget.appointment.status == AppointmentStatus.completed,
          isAbsent: widget.appointment.status == AppointmentStatus.absent,
          size: 38,
        ),
        title: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.appointment.patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isInChamber) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF16A34A)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.meeting_room_rounded,
                            size: 11,
                            color: Color(0xFF15803D),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'IN CHAMBER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (widget.appointment.isPaused) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF9333EA)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pause_circle_outline_rounded,
                            size: 11,
                            color: Color(0xFF7E22CE),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'PAUSED / RESUMABLE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7E22CE),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppointmentStatusChip(
              status: widget.appointment.status,
              isCompact: true,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.appointment.patientPhone} • ${AppFormatters.doctorTitle(widget.appointment.doctorName)}',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PaymentBadge(
                paymentType: widget.appointment.paymentType,
                amount: widget.appointment.amountCollected,
                isCompact: true,
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Payment Type:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 6.0,
                  children: [
                    _buildChoiceChip(PaymentType.paidCash, 'Paid Cash'),
                    _buildChoiceChip(PaymentType.paidUpi, 'Paid UPI'),
                    if (widget.appointment.paymentType ==
                        PaymentType.paidCarryOver)
                      _buildChoiceChip(
                        PaymentType.paidCarryOver,
                        'Prepaid Carry-Over',
                      ),
                    _buildChoiceChip(PaymentType.freeReview, 'Free Review'),
                    _buildChoiceChip(
                      PaymentType.freeFamily,
                      'Courtesy Waiver',
                    ),
                    _buildChoiceChip(PaymentType.unpaid, 'Unpaid'),
                    _buildChoiceChip(PaymentType.postPay, 'Post-Pay'),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.appointment.visitStatus == VisitStatus.booked) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 400;
                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFFB45309),
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Patient booked via phone/advance. Admit to lobby once arrived at desk.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F766E),
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(
                                  Icons.how_to_reg_rounded,
                                  size: 16,
                                ),
                                label: const Text('Check In Patient'),
                                onPressed: () => QuickCheckInDialog.show(
                                  context,
                                  appointment: widget.appointment,
                                ),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFB45309),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Patient booked via phone/advance. Admit to lobby once arrived at desk.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(
                                Icons.how_to_reg_rounded,
                                size: 16,
                              ),
                              label: const Text('Check In'),
                              onPressed: () => QuickCheckInDialog.show(
                                context,
                                appointment: widget.appointment,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                if (widget.appointment.status == AppointmentStatus.pending) ...[
                  AccordionDispatchSection(
                    appointment: widget.appointment,
                    isInChamber: widget.isInChamber,
                  ),
                  const SizedBox(height: 12),
                ],
                AccordionStatusActions(
                  appointment: widget.appointment,
                  onUpdateStatus: (status) => _updateStatus(context, status),
                ),
                if (ClinicConfig.current.features.enableTokenReceiptPrint) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF5EEAD4)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text(
                        'Print Token Slip',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () =>
                          TokenReceiptDialog.show(context, widget.appointment),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(PaymentType type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedPaymentType == type,
      onSelected: (selected) async {
        if (!selected) return;

        if (type == PaymentType.freeReview) {
          final provider = Provider.of<ClinicProvider>(context, listen: false);
          final appts = await provider.getAppointmentsForPatient(
            widget.appointment.patientPhone,
          );
          final doctor = provider.doctors
              .where((d) => d.id == widget.appointment.doctorId)
              .firstOrNull;
          final freeReviewDays = doctor?.freeReviewDays ?? 14;

          final eligibility = AppointmentEngine.evaluateReviewEligibility(
            patientHistory: appts,
            doctorId: widget.appointment.doctorId,
            targetDate: widget.appointment.scheduledDate,
            doctorName: widget.appointment.doctorName,
            freeReviewDays: freeReviewDays,
          );

          if (!eligibility.hasVisitedDoctorEarlier) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Free Review is only allowed for patients who previously visited ${AppFormatters.doctorTitle(widget.appointment.doctorName)}.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          if (!eligibility.isWithinReviewPeriod) {
            if (!mounted) return;
            final dateStr = eligibility.lastVisitDate != null
                ? AppFormatters.date(eligibility.lastVisitDate!)
                : 'N/A';
            final proceed =
                await BookingEligibilityBanner.showReviewWarningDialog(
                  context,
                  doctorName: widget.appointment.doctorName,
                  dateStr: dateStr,
                  days: eligibility.daysSinceLastVisit ?? 15,
                  policyDays: freeReviewDays,
                );
            if (proceed != true) return;
          }
        }

        setState(() {
          _selectedPaymentType = type;
        });
      },
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    AppointmentStatus status,
  ) async {
    final provider = Provider.of<ClinicProvider>(context, listen: false);
    final doctor = provider.getDoctorById(widget.appointment.doctorId);

    int amount = widget.appointment.amountCollected;
    VisitStatus? vStatus;
    String? refStatus = widget.appointment.refundStatus;
    if (status == AppointmentStatus.completed) {
      vStatus = VisitStatus.completed;
      amount = AppointmentEngine.resolveConsultationFee(
        doctor: doctor,
        paymentType: _selectedPaymentType,
      );
    } else if (status == AppointmentStatus.absent) {
      vStatus = VisitStatus.cancelled;
      amount = widget.appointment.amountCollected;
      if (amount > 0 && (refStatus == 'none' || refStatus == null)) {
        refStatus = 'pending_refund';
      }
    }

    try {
      await provider.updateAppointmentStatus(
        widget.appointment.id,
        status.name,
        _selectedPaymentType.name,
        amount,
        visitStatus: vStatus,
        refundStatus: refStatus,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating status: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
