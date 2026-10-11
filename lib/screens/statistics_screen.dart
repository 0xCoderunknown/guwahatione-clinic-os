import 'package:flutter/material.dart';

import '../core/engines/engines.dart';
import '../models/appointment.dart';
import '../services/firebase_service.dart'; // Direct service access for clean stream
import '../widgets/widgets.dart';
import 'doctor_daily_details_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _selectedDate = DateTime.now();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    final canPop = Navigator.canPop(context);
    final showAppBar = !isDesktop || canPop;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text("Daily Statistics"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: ClinicDateNavBar(
              selectedDate: _selectedDate,
              onDateChanged: (picked) {
                setState(() => _selectedDate = picked);
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: _firebaseService.getAppointmentsForDate(_selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No appointments for this date."),
                  );
                }

                final appointments = snapshot.data!;
                final doctorStats =
                    RevenueEngine.calculateDoctorAnalytics(appointments);

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: doctorStats.length,
                  itemBuilder: (context, index) {
                    final stats = doctorStats[index];
                    return DoctorStatisticsCard(
                      stats: stats,
                      onTap: () {
                        final doctorAppts = appointments
                            .where((a) => a.doctorId == stats.doctorId)
                            .toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorDailyDetailsScreen(
                              doctorName: stats.doctorName,
                              date: _selectedDate,
                              appointments: doctorAppts,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(), // Can't see future stats
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
}

