import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../services/firebase_service.dart';
import '../utils/formatters.dart';
import '../widgets/widgets.dart';

/// Reception screen for managing, filtering, and calling appointments in queue.
class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showAll = false; // Default: Show pending only
  final FirebaseService _firebaseService = FirebaseService();

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _showAll = !_isToday;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                // Date Selector
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isToday
                                  ? "Today (${AppFormatters.date(_selectedDate)})"
                                  : AppFormatters.dateWithDay(_selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Show All Toggle
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        "Show Completed",
                        style: TextStyle(fontSize: 12),
                      ),
                      Switch(
                        value: _showAll,
                        onChanged: _isToday
                            ? (val) {
                                setState(() {
                                  _showAll = val;
                                });
                              }
                            : null, // Locked if not today
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Appointment List Stream
          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: _firebaseService.getAppointmentsForDate(_selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allAppointments = snapshot.data ?? [];
                final visibleAppointments = _showAll
                    ? allAppointments
                    : allAppointments
                        .where((a) => a.status == AppointmentStatus.pending)
                        .toList();

                if (visibleAppointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showAll
                              ? 'No appointments found.'
                              : 'No pending appointments.\nToggle "Show Completed" to see history.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: visibleAppointments.length,
                  itemBuilder: (context, index) {
                    return AppointmentAccordion(
                      appointment: visibleAppointments[index],
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
}
