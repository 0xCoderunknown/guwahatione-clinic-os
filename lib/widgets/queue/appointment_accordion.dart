import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../../models/chamber_session.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_url.dart';
import '../booking/booking_eligibility_banner.dart';
import '../booking/quick_check_in_dialog.dart';
import '../common/appointment_status_chip.dart';
import '../common/payment_badge.dart';
import '../common/token_badge.dart';

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
  final bool isBypassed;
  final bool showDoctorTag;

  const AppointmentAccordion({
    super.key,
    required this.appointment,
    this.isExpanded,
    this.onExpansionChanged,
    this.isInChamber = false,
    this.isBypassed = false,
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

    if (widget.isExpanded != null && widget.isExpanded != oldWidget.isExpanded) {
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
    } else if (widget.isBypassed) {
      cardBg = const Color(0xFFFFFBEB); // Amber 50
      cardBorder = const BorderSide(color: Color(0xFFFCD34D), width: 1.2);
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
                  ] else if (widget.isBypassed) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: Color(0xFFB45309),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'BYPASSED / LATE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
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
                    _buildChoiceChip(PaymentType.paidCash, 'Paid (Cash)'),
                    _buildChoiceChip(PaymentType.paidUpi, 'Paid (UPI)'),
                    _buildChoiceChip(PaymentType.postPay, 'Post-Pay (Exit)'),
                    _buildChoiceChip(PaymentType.unpaid, 'Unpaid'),
                    _buildChoiceChip(PaymentType.freeReview, 'Free Review'),
                    _buildChoiceChip(PaymentType.freeFamily, 'Family / VVIP'),
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
                    child: Row(
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
                          icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                          label: const Text('Check In'),
                          onPressed: () => QuickCheckInDialog.show(
                            context,
                            appointment: widget.appointment,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.appointment.status == AppointmentStatus.pending) ...[
                  StreamBuilder<ChamberSession>(
                    stream: Provider.of<ClinicProvider>(context, listen: false)
                        .streamChamberSession(
                          widget.appointment.doctorId,
                          widget.appointment.scheduledDate,
                        ),
                    builder: (context, chamberSnap) {
                      final session = chamberSnap.data;
                      final isDoctorReady = session?.isReadyForNext ?? false;
                      final isDoctorOnBreak =
                          session?.isConsultationEnded ?? false;
                      final activeApptId = session?.activeAppointmentId;
                      final activeQueueNum = session?.activeQueueNumber;
                      final activePatName = session?.patientName ?? 'Patient';

                      final isThisInChamber =
                          widget.isInChamber ||
                          (activeApptId == widget.appointment.id);
                      final isAnotherPatientInChamber =
                          activeApptId != null &&
                          activeApptId.isNotEmpty &&
                          activeApptId != widget.appointment.id;

                      String buttonLabel = 'SEND IN TO DOCTOR';
                      Color buttonBg = const Color(0xFF0F766E); // Teal 700
                      IconData buttonIcon = Icons.login_rounded;

                      if (isDoctorReady) {
                        buttonLabel = 'SEND IN (Doctor is Ready)';
                        buttonBg = const Color(0xFF15803D); // Green 700
                        buttonIcon = Icons.check_circle_outline_rounded;
                      } else if (isDoctorOnBreak) {
                        buttonLabel = 'Doctor on Break • Send In Anyway';
                        buttonBg = const Color(0xFFB45309); // Amber 700
                        buttonIcon = Icons.coffee_rounded;
                      } else if (isAnotherPatientInChamber) {
                        buttonLabel =
                            'SEND IN (Token #$activeQueueNum Inside)';
                        buttonBg = const Color(0xFFD97706); // Amber 600
                        buttonIcon = Icons.swap_horiz_rounded;
                      } else if (isThisInChamber) {
                        buttonLabel = 'Already in Chamber';
                        buttonBg = const Color(0xFF059669);
                        buttonIcon = Icons.meeting_room_rounded;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isDoctorReady)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF86EFAC),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: Color(0xFF15803D),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${AppFormatters.doctorTitle(widget.appointment.doctorName)} is READY for next patient!',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isDoctorOnBreak)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.coffee_rounded,
                                    size: 14,
                                    color: Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${AppFormatters.doctorTitle(widget.appointment.doctorName)} is taking a breather. Verify patient presence before dispatching.',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isAnotherPatientInChamber)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFCD34D),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Token #$activeQueueNum ($activePatName) is currently consulting ${AppFormatters.doctorTitle(widget.appointment.doctorName)}.',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFB45309),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: buttonBg,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            icon: Icon(buttonIcon, size: 18),
                            label: Text(
                              buttonLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () async {
                              final clinic = Provider.of<ClinicProvider>(
                                context,
                                listen: false,
                              );

                              // Guard 1: Another patient is already in chamber
                              if (isAnotherPatientInChamber) {
                                final proceed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Row(
                                      children: [
                                        Icon(
                                          Icons.swap_horiz_rounded,
                                          color: Color(0xFFD97706),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Chamber Currently Occupied'),
                                      ],
                                    ),
                                    content: Text(
                                      '${AppFormatters.doctorTitle(widget.appointment.doctorName)} is currently consulting '
                                      'Token #$activeQueueNum ($activePatName).\n\n'
                                      'Admitting Token #${widget.appointment.queueNumber} (${widget.appointment.patientName}) '
                                      'will replace the active patient in chamber. Send inside anyway?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Wait'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFD97706,
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Send Inside Anyway'),
                                      ),
                                    ],
                                  ),
                                );
                                if (proceed != true) return;
                              } else if (isDoctorOnBreak) {
                                // Guard 2: Doctor taking a breather
                                final proceed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Row(
                                      children: [
                                        Icon(
                                          Icons.coffee_rounded,
                                          color: Colors.amber.shade800,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Doctor Taking Breather'),
                                      ],
                                    ),
                                    content: Text(
                                      '${AppFormatters.doctorTitle(widget.appointment.doctorName)} is taking a breather and hasn\'t clicked \'NEXT PATIENT\' yet.\n\n'
                                      'Send Token #${widget.appointment.queueNumber} (${widget.appointment.patientName}) inside anyway?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Wait for Doctor'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFB45309,
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Send Inside Anyway'),
                                      ),
                                    ],
                                  ),
                                );
                                if (proceed != true) return;
                              }

                              await clinic.callTokenIntoChamber(
                                doctorId: widget.appointment.doctorId,
                                date: widget.appointment.scheduledDate,
                                appointment: widget.appointment,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Dispatched Token #${widget.appointment.queueNumber} (${widget.appointment.patientName}) to ${AppFormatters.doctorTitle(widget.appointment.doctorName)}',
                                    ),
                                    backgroundColor: Colors.teal.shade800,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          _updateStatus(context, AppointmentStatus.completed);
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Mark Complete'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () async {
                          final confirmAbsent = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Mark Patient Absent?'),
                              content: Text(
                                'Mark Token #${widget.appointment.queueNumber} (${widget.appointment.patientName}) as absent?\n\n'
                                'The token slot will be preserved on record with ₹0 fee collected. '
                                'Only mark absent if the patient cancelled or the clinic shift has ended.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Confirm Absent'),
                                ),
                              ],
                            ),
                          );
                          if (confirmAbsent == true && context.mounted) {
                            await _updateStatus(
                              context,
                              AppointmentStatus.absent,
                            );
                          }
                        },
                        icon: const Icon(Icons.person_off_outlined, size: 18),
                        label: const Text('Mark Absent'),
                      ),
                    ),
                  ],
                ),
                if (widget.appointment.status == AppointmentStatus.completed) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(
                          color: Color(0xFF16A34A),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Send WhatsApp Digital Prescription',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final clinic = Provider.of<ClinicProvider>(
                          context,
                          listen: false,
                        );
                        final consult =
                            await clinic.getConsultationForAppointment(
                              widget.appointment.id,
                              widget.appointment.patientPhone,
                            );
                        String msg;
                        if (consult != null) {
                          msg = WhatsAppEngine.formatPrescriptionMessage(
                            consultation: consult,
                            queueNumber: widget.appointment.queueNumber,
                          );
                        } else {
                          msg =
                              '*GuwahatiOne Clinic — OPD Visit Receipt*\n'
                              '🗓️ Date: ${AppFormatters.date(widget.appointment.scheduledDate)} | Token: #${widget.appointment.queueNumber}\n'
                              '👤 Patient: ${widget.appointment.patientName}\n'
                              '👨‍⚕️ Doctor: ${AppFormatters.doctorTitle(widget.appointment.doctorName)}\n'
                              '💵 Amount Paid: ${AppFormatters.currency(widget.appointment.amountCollected)}\n\n'
                              'Status: Completed\n'
                              'Thank you for visiting GuwahatiOne Clinic.';
                        }
                        final link = WhatsAppEngine.buildDeepLink(
                          phone: widget.appointment.patientPhone,
                          message: msg,
                        );
                        openUrl(link);
                      },
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
          final eligibility = AppointmentEngine.evaluateReviewEligibility(
            patientHistory: appts,
            doctorId: widget.appointment.doctorId,
            targetDate: widget.appointment.scheduledDate,
            doctorName: widget.appointment.doctorName,
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

          if (!eligibility.isWithin14Days) {
            if (!mounted) return;
            final dateStr = eligibility.lastVisitDate != null
                ? AppFormatters.date(eligibility.lastVisitDate!)
                : 'N/A';
            final proceed =
                await BookingEligibilityBanner.showFourteenDaysWarningDialog(
                  context,
                  doctorName: widget.appointment.doctorName,
                  dateStr: dateStr,
                  days: eligibility.daysSinceLastVisit ?? 15,
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

    int amount = 0;
    VisitStatus? vStatus;
    if (status == AppointmentStatus.completed) {
      vStatus = VisitStatus.completed;
      amount = AppointmentEngine.resolveConsultationFee(
        doctor: doctor,
        paymentType: _selectedPaymentType,
      );
    } else if (status == AppointmentStatus.absent) {
      vStatus = VisitStatus.cancelled;
      amount = 0;
    }

    try {
      await provider.updateAppointmentStatus(
        widget.appointment.id,
        status.name,
        _selectedPaymentType.name,
        amount,
        visitStatus: vStatus,
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
