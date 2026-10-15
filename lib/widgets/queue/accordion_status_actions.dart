import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_url.dart';

/// Status action buttons and WhatsApp prescription delivery for appointment queue tile.
///
/// Provides [Mark Complete] and [Mark Absent] buttons with audit-proof absent confirmation
/// modals, as well as a 1-tap WhatsApp digital prescription button when completed.
class AccordionStatusActions extends StatelessWidget {
  final Appointment appointment;
  final ValueChanged<AppointmentStatus> onUpdateStatus;

  const AccordionStatusActions({
    super.key,
    required this.appointment,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => onUpdateStatus(AppointmentStatus.completed),
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
                        'Mark Token #${appointment.queueNumber} (${appointment.patientName}) as absent?\n\n'
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
                  if (confirmAbsent == true) {
                    onUpdateStatus(AppointmentStatus.absent);
                  }
                },
                icon: const Icon(Icons.person_off_outlined, size: 18),
                label: const Text('Mark Absent'),
              ),
            ),
          ],
        ),
        if (appointment.status == AppointmentStatus.completed) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text(
                'Send WhatsApp Digital Prescription',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final clinic = Provider.of<ClinicProvider>(
                  context,
                  listen: false,
                );
                final consult = await clinic.getConsultationForAppointment(
                  appointment.id,
                  appointment.patientPhone,
                );
                String msg;
                if (consult != null) {
                  final doc = clinic.doctors
                      .where((d) => d.id == appointment.doctorId)
                      .firstOrNull;
                  msg = WhatsAppEngine.formatPrescriptionMessage(
                    consultation: consult,
                    queueNumber: appointment.queueNumber,
                    freeReviewDays: doc?.freeReviewDays,
                  );
                } else {
                  msg =
                      '*GuwahatiOne Clinic — OPD Visit Receipt*\n'
                      '🗓️ Date: ${AppFormatters.date(appointment.scheduledDate)} | Token: #${appointment.queueNumber}\n'
                      '👤 Patient: ${appointment.patientName}\n'
                      '👨‍⚕️ Doctor: ${AppFormatters.doctorTitle(appointment.doctorName)}\n'
                      '💵 Amount Paid: ${AppFormatters.currency(appointment.amountCollected)}\n\n'
                      'Status: Completed\n'
                      'Thank you for visiting GuwahatiOne Clinic.';
                }
                final link = WhatsAppEngine.buildDeepLink(
                  phone: appointment.patientPhone,
                  message: msg,
                );
                openUrl(link);
              },
            ),
          ),
        ],
      ],
    );
  }
}
