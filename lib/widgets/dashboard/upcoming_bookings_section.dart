import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';
import '../common/token_badge.dart';

/// 7-Day advance bookings view displayed in the reception dashboard queue card.
class UpcomingBookingsSection extends StatelessWidget {
  final ClinicProvider provider;

  const UpcomingBookingsSection({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Appointment>>(
      stream: provider.streamUpcomingAppointments(daysAhead: 7),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Center(
              child: Text(
                'Unable to load upcoming bookings: ${snapshot.error}',
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
          );
        }

        final upcomingList = snapshot.data ?? [];
        if (upcomingList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 44,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No advance bookings scheduled for the next 7 days',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Advance appointments booked for tomorrow onwards will appear here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Group appointments by formatted calendar date (DD-MM-YYYY)
        final Map<String, List<Appointment>> grouped = {};
        for (final appt in upcomingList) {
          final dateKey = AppFormatters.date(appt.scheduledDate);
          grouped.putIfAbsent(dateKey, () => []).add(appt);
        }

        final isMobile = MediaQuery.of(context).size.width < 750;

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            for (final entry in grouped.entries) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: const Color(0xFFF8FAFC),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Color(0xFF0F766E),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Text(
                        '${entry.value.length} booking${entry.value.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...entry.value.map((appt) {
                return _buildUpcomingAppointmentRow(appt, isMobile: isMobile);
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildUpcomingAppointmentRow(
    Appointment appt, {
    required bool isMobile,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          TokenBadge(
            queueNumber: appt.queueNumber,
            doctorTag: AppFormatters.doctorInitials(appt.doctorName),
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        appt.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (appt.patientAgeDisplay != null &&
                        appt.patientAgeDisplay!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${appt.patientAgeDisplay!})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      appt.patientPhone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppFormatters.doctorTitle(appt.doctorName),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Text(
              appt.paymentType == PaymentType.paidCash ||
                      appt.paymentType == PaymentType.paidUpi
                  ? 'Paid ₹${appt.amountCollected}'
                  : 'Pay at Desk',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
