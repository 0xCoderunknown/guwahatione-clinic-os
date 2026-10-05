import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../services/firebase_service.dart'; // Direct service access for clean stream
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Statistics"),
        actions: [
          // DATE PICKER BUTTON
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.teal.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.date_range, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
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

                // GROUP BY DOCTOR LOGIC
                // Map<DoctorID, List<Appointment>>
                final Map<String, List<Appointment>> doctorGroups = {};
                for (var appt in appointments) {
                  if (!doctorGroups.containsKey(appt.doctorId)) {
                    doctorGroups[appt.doctorId] = [];
                  }
                  doctorGroups[appt.doctorId]!.add(appt);
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: doctorGroups.entries.map((entry) {
                    return _buildDoctorCard(context, entry.value);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, List<Appointment> doctorAppts) {
    if (doctorAppts.isEmpty) return const SizedBox.shrink();

    // CALCULATE STATS
    final doctorName = doctorAppts.first.doctorName;
    final totalPatients = doctorAppts.length;

    final completed = doctorAppts
        .where((a) => a.status == AppointmentStatus.completed)
        .length;
    final pending = doctorAppts
        .where((a) => a.status == AppointmentStatus.pending)
        .length;
    final absent = doctorAppts
        .where((a) => a.status == AppointmentStatus.absent)
        .length;
    final free = doctorAppts
        .where((a) => a.paymentType != PaymentType.paid)
        .length;

    // Revenue: Sum of 'amountCollected' for COMPLETED only
    final revenue = doctorAppts
        .where((a) => a.status == AppointmentStatus.completed)
        .fold(0, (sum, a) => sum + a.amountCollected);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // NAVIGATE TO DETAIL SCREEN
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorDailyDetailsScreen(
                doctorName: doctorName,
                date: _selectedDate,
                appointments: doctorAppts,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    doctorName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "₹$revenue",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statItem("Total", "$totalPatients", Colors.black),
                  _statItem("Done", "$completed", Colors.green),
                  _statItem("Pending", "$pending", Colors.orange),
                  _statItem("Free/Fam", "$free", Colors.blue),
                ],
              ),
              if (absent > 0) ...[
                const SizedBox(height: 8),
                Text(
                  "$absent patient(s) marked absent/no-show",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
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
