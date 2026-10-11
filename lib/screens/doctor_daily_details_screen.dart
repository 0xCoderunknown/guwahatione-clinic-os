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
