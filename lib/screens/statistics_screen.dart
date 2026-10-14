import 'package:flutter/material.dart';

import '../core/engines/engines.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _selectedDate = DateTime.now();
  final BookingService _bookingService = BookingService();

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
              stream: _bookingService.getAppointmentsForDate(_selectedDate),
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
                final doctorStats = RevenueEngine.calculateDoctorAnalytics(
                  appointments,
                );

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

/// Card displaying doctor-specific daily consultation volume, review count,
/// and realized revenue statistics.
class DoctorStatisticsCard extends StatelessWidget {
  final DoctorAnalyticsSummary stats;
  final VoidCallback? onTap;

  const DoctorStatisticsCard({super.key, required this.stats, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
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
                    stats.doctorName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "₹${stats.realizedRevenue}",
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
                  _StatMetricItem(
                    label: "Total",
                    value: "${stats.totalPatients}",
                    color: Colors.black,
                  ),
                  _StatMetricItem(
                    label: "Done",
                    value: "${stats.completed}",
                    color: Colors.green,
                  ),
                  _StatMetricItem(
                    label: "Pending",
                    value: "${stats.pending}",
                    color: Colors.orange,
                  ),
                  _StatMetricItem(
                    label: "Free/Fam",
                    value: "${stats.free}",
                    color: Colors.blue,
                  ),
                ],
              ),
              if (stats.absent > 0) ...[
                const SizedBox(height: 8),
                Text(
                  "${stats.absent} patient(s) marked absent/no-show",
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
}

class _StatMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatMetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}
