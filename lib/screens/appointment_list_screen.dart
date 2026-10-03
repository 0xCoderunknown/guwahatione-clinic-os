import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../providers/clinic_provider.dart';
import '../services/firebase_service.dart';
import '../utils/app_constants.dart';

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
        if (!_isToday) {
          _showAll = true;
        } else {
          _showAll = false;
        }
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
                                  ? "Today"
                                  : DateFormat(
                                      'EEE, MMM d',
                                    ).format(_selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
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

          // APPOINTMENT LIST
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

class AppointmentAccordion extends StatefulWidget {
  final Appointment appointment;

  const AppointmentAccordion({super.key, required this.appointment});

  @override
  State<AppointmentAccordion> createState() => _AppointmentAccordionState();
}

class _AppointmentAccordionState extends State<AppointmentAccordion> {
  late PaymentType _selectedPaymentType;

  @override
  void initState() {
    super.initState();
    _selectedPaymentType = widget.appointment.paymentType;
  }

  @override
  void didUpdateWidget(covariant AppointmentAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appointment.paymentType != widget.appointment.paymentType) {
      _selectedPaymentType = widget.appointment.paymentType;
    }
  }

  @override
  Widget build(BuildContext context) {
    Icon statusIcon;
    switch (widget.appointment.status) {
      case AppointmentStatus.pending:
        statusIcon = const Icon(Icons.hourglass_empty, color: Colors.orange);
        break;
      case AppointmentStatus.completed:
        statusIcon = const Icon(Icons.check_circle, color: Colors.green);
        break;
      case AppointmentStatus.cancelled:
        statusIcon = const Icon(Icons.cancel, color: Colors.grey);
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        title: Text(
          widget.appointment.patientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${widget.appointment.patientPhone} • Queue: ${widget.appointment.queueNumber}',
        ),
        leading: statusIcon,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _selectedPaymentType = widget.appointment.paymentType;
            }
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Payment Type:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: [
                    _buildChoiceChip(PaymentType.paid, 'Paid (₹500)'),
                    _buildChoiceChip(PaymentType.freeReview, 'Free Review'),
                    _buildChoiceChip(PaymentType.freeFamily, 'Family'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _updateStatus(context, AppointmentStatus.completed);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Mark Complete'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () {
                          _updateStatus(context, AppointmentStatus.cancelled);
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(PaymentType type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedPaymentType == type,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPaymentType = type;
          });
        }
      },
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    AppointmentStatus status,
  ) async {
    final provider = Provider.of<ClinicProvider>(context, listen: false);

    int amount = 0;
    if (status == AppointmentStatus.completed) {
      amount = (_selectedPaymentType == PaymentType.paid)
          ? AppConstants.defaultConsultationFee
          : 0;
    } else if (status == AppointmentStatus.cancelled) {
      amount = 0;
    }

    try {
      await provider.updateAppointmentStatus(
        widget.appointment.id,
        status.name,
        _selectedPaymentType.name,
        amount,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating status: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
