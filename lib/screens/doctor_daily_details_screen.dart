import 'package:flutter/material.dart';

import '../core/engines/engines.dart';
import '../models/appointment.dart';
import '../utils/formatters.dart';

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
    // Calculate Totals for Bottom Bar using pure engine
    final totalFees = RevenueEngine.calculateRealizedRevenue(appointments);
    final totalPatients = appointments.length;

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
      body: Column(
        children: [
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

          Expanded(
            child: ListView.separated(
              itemCount: appointments.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final appt = appointments[index];

                // Color coding for status
                Color statusColor = Colors.grey;
                if (appt.status == AppointmentStatus.completed) {
                  statusColor = Colors.green;
                }
                if (appt.status == AppointmentStatus.absent) {
                  statusColor = Colors.red;
                }

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
                            if (appt.paymentType != PaymentType.paid)
                              Text(
                                appt.paymentType.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Status
                      Expanded(
                        child: Text(
                          appt.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
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
                  "Total Patients: $totalPatients",
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
      ),
    );
  }
}
