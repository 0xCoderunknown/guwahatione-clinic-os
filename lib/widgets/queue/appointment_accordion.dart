import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../../providers/clinic_provider.dart';
import '../booking/booking_eligibility_banner.dart';
import '../common/appointment_status_chip.dart';
import '../common/payment_badge.dart';
import '../common/token_badge.dart';

/// Accordion card for reception appointment queue management.
class AppointmentAccordion extends StatefulWidget {
  final Appointment appointment;

  const AppointmentAccordion({super.key, required this.appointment});

  @override
  State<AppointmentAccordion> createState() => _AppointmentAccordionState();
}

class _AppointmentAccordionState extends State<AppointmentAccordion> {
  late PaymentType _selectedPaymentType;

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
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        leading: TokenBadge(
          queueNumber: widget.appointment.queueNumber,
          isCompleted: widget.appointment.status == AppointmentStatus.completed,
          isAbsent: widget.appointment.status == AppointmentStatus.absent,
          size: 38,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.appointment.patientName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                  '${widget.appointment.patientPhone} • Dr. ${widget.appointment.doctorName}',
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
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _selectedPaymentType = widget.appointment.paymentType;
            }
          });
        },
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
                  children: [
                    _buildChoiceChip(PaymentType.paid, 'Paid (₹500)'),
                    _buildChoiceChip(PaymentType.freeReview, 'Free Review'),
                    _buildChoiceChip(PaymentType.freeFamily, 'Family'),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.appointment.status == AppointmentStatus.pending) ...[
                  StreamBuilder(
                    stream: Provider.of<ClinicProvider>(context, listen: false)
                        .streamChamberSession(
                      widget.appointment.doctorId,
                      widget.appointment.scheduledDate,
                    ),
                    builder: (context, chamberSnap) {
                      final cData = chamberSnap.data?.data();
                      final cStatus = (cData?['status'] as String?) ?? 'idle';
                      final isDoctorReady = cStatus == 'ready_for_next';
                      final isDoctorOnBreak = cStatus == 'consultation_ended';

                      String buttonLabel = 'Call In / Start Consultation';
                      Color buttonBg = Colors.teal.shade700;
                      IconData buttonIcon = Icons.record_voice_over_rounded;

                      if (isDoctorReady) {
                        buttonLabel = 'Send Inside (Doctor is Ready)';
                        buttonBg = const Color(0xFF15803D);
                        buttonIcon = Icons.login_rounded;
                      } else if (isDoctorOnBreak) {
                        buttonLabel = 'Doctor on Break • Call In Anyway';
                        buttonBg = const Color(0xFFB45309);
                        buttonIcon = Icons.coffee_rounded;
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
                                      'Dr. ${widget.appointment.doctorName} is READY for next patient!',
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
                                      'Dr. ${widget.appointment.doctorName} is taking a breather. Verify patient presence before calling.',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFB45309),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
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

                              if (isDoctorOnBreak) {
                                final proceed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Row(
                                      children: [
                                        Icon(Icons.coffee_rounded, color: Colors.amber.shade800),
                                        const SizedBox(width: 8),
                                        const Text('Doctor Taking Breather'),
                                      ],
                                    ),
                                    content: Text(
                                      'Dr. ${widget.appointment.doctorName} is taking a breather and hasn\'t clicked \'NEXT PATIENT\' yet.\n\n'
                                      'Send Token #${widget.appointment.queueNumber} (${widget.appointment.patientName}) inside anyway?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Wait for Doctor'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB45309)),
                                        onPressed: () => Navigator.pop(ctx, true),
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
                                      'Admitted Token #${widget.appointment.queueNumber} (${widget.appointment.patientName}) to Dr. ${widget.appointment.doctorName} chamber',
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
                        ),
                        onPressed: () {
                          _updateStatus(context, AppointmentStatus.completed);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Mark Complete'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        onPressed: () {
                          _updateStatus(context, AppointmentStatus.absent);
                        },
                        icon: const Icon(Icons.person_off_outlined),
                        label: const Text('Mark Absent'),
                      ),
                    ),
                  ],
                ),
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
                  'Free Review is only allowed for patients who previously visited Dr. ${widget.appointment.doctorName}.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          if (!eligibility.isWithin14Days) {
            if (!mounted) return;
            final dateStr = eligibility.lastVisitDate != null
                ? DateFormat('dd MMM yyyy').format(eligibility.lastVisitDate!)
                : 'N/A';
            final proceed = await BookingEligibilityBanner.showFourteenDaysWarningDialog(
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
    final doctor = provider.doctors
        .where((d) => d.id == widget.appointment.doctorId)
        .firstOrNull;

    int amount = 0;
    if (status == AppointmentStatus.completed) {
      amount = AppointmentEngine.resolveConsultationFee(
        doctor: doctor,
        paymentType: _selectedPaymentType,
      );
    } else if (status == AppointmentStatus.absent) {
      amount = 0;
    }

    try {
      await provider.updateAppointmentStatus(
        widget.appointment.id,
        status.name,
        _selectedPaymentType.name,
        amount,
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
