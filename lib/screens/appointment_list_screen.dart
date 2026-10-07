import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/patient_review_eligibility.dart';
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
      case AppointmentStatus.absent:
        statusIcon = const Icon(Icons.person_off, color: Colors.grey);
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
          '${widget.appointment.patientPhone} • Queue: ${widget.appointment.queueNumber} • ${widget.appointment.doctorName}',
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
                if (widget.appointment.status == AppointmentStatus.pending) ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.record_voice_over_rounded, size: 18),
                    label: const Text('Call In / Start Consultation',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: () async {
                      final clinic = Provider.of<ClinicProvider>(context, listen: false);
                      await clinic.callTokenIntoChamber(
                        doctorId: widget.appointment.doctorId,
                        date: widget.appointment.scheduledDate,
                        appointment: widget.appointment,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Called Token #${widget.appointment.queueNumber} (${widget.appointment.patientName}) to Dr. ${widget.appointment.doctorName} chamber',
                            ),
                            backgroundColor: Colors.teal.shade800,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
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
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        onPressed: () {
                          _updateStatus(context, AppointmentStatus.absent);
                        },
                        icon: const Icon(Icons.person_off_outlined),
                        label: const Text('Mark Absent'),
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
      onSelected: (selected) async {
        if (!selected) return;

        if (type == PaymentType.freeReview) {
          final provider = Provider.of<ClinicProvider>(context, listen: false);
          final appts = await provider.getAppointmentsForPatient(
            widget.appointment.patientPhone,
          );
          final eligibility = PatientReviewEligibility.calculate(
            appointments: appts,
            doctorId: widget.appointment.doctorId,
            targetDate: widget.appointment.scheduledDate,
            doctorName: widget.appointment.doctorName,
          );

          if (!eligibility.hasVisitedDoctorEarlier) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Free Review is only allowed for patients who previously visited Dr. ${widget.appointment.doctorName}.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          if (!eligibility.isWithin14Days) {
            if (!mounted) return;
            final dateStr = eligibility.lastVisitDate != null
                ? DateFormat('dd MMM yyyy').format(eligibility.lastVisitDate!)
                : 'N/A';
            final proceed = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                icon: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 48,
                ),
                title: const Text(
                  '14 Days Passed Warning',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ 14 days have passed since this patient\'s last visit with Dr. ${widget.appointment.doctorName}.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Last Visit: $dateStr'),
                          Text(
                            '• Days Elapsed: ${eligibility.daysSinceLastVisit} days (Policy limit: 14 days)',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Do you want to proceed with a Free Review anyway?',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Allow Free Review'),
                  ),
                ],
              ),
            );
            if (proceed != true) return;
          }
        }

        setState(() {
          _selectedPaymentType = type;
        });
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
    } else if (status == AppointmentStatus.absent) {
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
