import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../common/payment_badge.dart';
import '../common/token_badge.dart';

/// Top-level collapsible accordion card archiving completed consultations.
///
/// Keeps the active receptionist queue clean and uncluttered by tucking
/// finished patients out of the primary operational flow.
class CompletedConsultationsAccordion extends StatefulWidget {
  final List<Appointment> completedAppointments;

  const CompletedConsultationsAccordion({
    super.key,
    required this.completedAppointments,
  });

  @override
  State<CompletedConsultationsAccordion> createState() =>
      _CompletedConsultationsAccordionState();
}

class _CompletedConsultationsAccordionState
    extends State<CompletedConsultationsAccordion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.completedAppointments.isEmpty) {
      return const SizedBox.shrink();
    }

    final count = widget.completedAppointments.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.green.shade200),
      ),
      color: const Color(0xFFF0FDF4), // Emerald 50
      child: Theme(
        // Remove default border lines in ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Color(0xFF15803D),
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Text(
                'Completed Consultations ($count)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Text(
                  'Archived',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            _isExpanded
                ? 'Tap to collapse completed list'
                : 'Tap to view $count finished consult${count == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.completedAppointments.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: Color(0xFFE2E8F0),
                ),
                itemBuilder: (context, index) {
                  final appt = widget.completedAppointments[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        TokenBadge(
                          queueNumber: appt.queueNumber,
                          isCompleted: true,
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appt.patientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${appt.patientPhone} • Dr. ${appt.doctorName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PaymentBadge(
                          paymentType: appt.paymentType,
                          amount: appt.amountCollected,
                          isCompact: true,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
