import 'package:flutter/material.dart';

import '../core/engines/engines.dart';
import '../models/appointment.dart';
import '../utils/formatters.dart';
import '../widgets/widgets.dart';

/// Screen displaying detailed patient-level financial and attendance breakdown for a doctor.
class DoctorDailyDetailsScreen extends StatelessWidget {
  final String doctorName;
  final DateTime date;
  final List<Appointment> appointments;

  const DoctorDailyDetailsScreen({
    super.key,
    required this.doctorName,
    required this.date,
    required this.appointments,
  });

  @override
  Widget build(BuildContext context) {
    final totalFees = RevenueEngine.calculateRealizedRevenue(appointments);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doctorName, style: const TextStyle(fontSize: 18)),
            Text(
              AppFormatters.date(date),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: DoctorDailyBreakdownTable(
        appointments: appointments,
        totalFees: totalFees,
      ),
    );
  }
}

/// Table presenting a doctor's patient consultations breakdown for a calendar date,
/// including patient payment type, consultation status badge, collected fee, and footer totals.
class DoctorDailyBreakdownTable extends StatelessWidget {
  final List<Appointment> appointments;
  final int totalFees;

  const DoctorDailyBreakdownTable({
    super.key,
    required this.appointments,
    required this.totalFees,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade200,
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  "Patient",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  "Status",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  "Fees",
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Appointment Rows
        Expanded(
          child: appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No consultations recorded for this doctor on this date.",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: appointments.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final appt = appointments[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      child: Row(
                        children: [
                          // Name & Type
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appt.patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (!appt.paymentType.isPaid)
                                  Text(
                                    appt.paymentType.displayName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          appt.paymentType == PaymentType.unpaid
                                          ? Colors.red
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Status
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AppointmentStatusChip(
                                status: appt.status,
                                visitStatus: appt.visitStatus,
                                isCompact: true,
                              ),
                            ),
                          ),
                          // Fees
                          Expanded(
                            child: Text(
                              "₹${appt.amountCollected}",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: appt.amountCollected > 0
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Summary Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            border: Border(top: BorderSide(color: Colors.teal.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Patients: ${appointments.length}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Total Fees: ₹$totalFees",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
