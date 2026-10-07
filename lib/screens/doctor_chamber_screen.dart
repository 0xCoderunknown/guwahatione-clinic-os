import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import 'consultation_encounter_screen.dart';

class DoctorChamberScreen extends StatefulWidget {
  final Doctor doctor;
  final bool isPreviewMode; // True if previewed by clinic owner

  const DoctorChamberScreen({
    super.key,
    required this.doctor,
    this.isPreviewMode = false,
  });

  @override
  State<DoctorChamberScreen> createState() => _DoctorChamberScreenState();
}

class _DoctorChamberScreenState extends State<DoctorChamberScreen> {
  DateTime _selectedDate = DateTime.now();
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription? _chamberSessionSub;
  String? _activeCallingApptId;
  String? _lastHandledCallingAppointmentId;
  bool _isAutoNavigating = false;
  List<Appointment> _latestAppointments = [];

  @override
  void initState() {
    super.initState();
    _listenToChamberSession();
  }

  @override
  void dispose() {
    _chamberSessionSub?.cancel();
    super.dispose();
  }

  void _listenToChamberSession() {
    _chamberSessionSub?.cancel();
    _chamberSessionSub = _firebaseService
        .streamChamberSession(widget.doctor.id, _selectedDate)
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data();
      if (data == null) return;

      final status = data['status'] as String?;
      final activeApptId = data['activeAppointmentId'] as String?;

      setState(() {
        _activeCallingApptId = (status == 'calling' || status == 'in_consultation')
            ? activeApptId
            : null;
      });

      if (status == 'calling' &&
          activeApptId != null &&
          activeApptId.isNotEmpty &&
          activeApptId != _lastHandledCallingAppointmentId &&
          !_isAutoNavigating) {
        _lastHandledCallingAppointmentId = activeApptId;
        _autoOpenConsultationForId(activeApptId);
      }
    });
  }

  Future<void> _autoOpenConsultationForId(String appointmentId) async {
    _isAutoNavigating = true;
    try {
      // Find from current stream list
      Appointment? targetAppt;
      for (final a in _latestAppointments) {
        if (a.id == appointmentId) {
          targetAppt = a;
          break;
        }
      }

      // If not in memory yet, wait briefly for stream snapshot
      if (targetAppt == null) {
        await Future.delayed(const Duration(milliseconds: 400));
        for (final a in _latestAppointments) {
          if (a.id == appointmentId) {
            targetAppt = a;
            break;
          }
        }
      }

      if (targetAppt != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Token #${targetAppt.queueNumber} (${targetAppt.patientName}) called into chamber! Auto-loading...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade800,
            duration: const Duration(seconds: 3),
          ),
        );

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ConsultationEncounterScreen(
              appointment: targetAppt!,
              doctor: widget.doctor,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        _isAutoNavigating = false;
      }
    }
  }

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
      });
      _listenToChamberSession();
    }
  }

  void _changeDate(int dayDelta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: dayDelta));
    });
    _listenToChamberSession();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.local_hospital_rounded, color: Colors.teal.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.doctor.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.isPreviewMode ? Colors.purple.shade50 : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: widget.isPreviewMode ? Colors.purple.shade200 : Colors.teal.shade200,
                          ),
                        ),
                        child: Text(
                          widget.isPreviewMode ? 'OWNER PREVIEW' : 'CHAMBER CATALOG',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: widget.isPreviewMode ? Colors.purple.shade700 : Colors.teal.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.doctor.specialty} • Fee: ₹${widget.doctor.consultationFee}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.isPreviewMode)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              tooltip: 'Close Preview',
              onPressed: () => Navigator.pop(context),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'Logout of Chamber',
              onPressed: () => _confirmLogout(context),
            ),
        ],
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _firebaseService.getAppointmentsForDoctorAndDate(
          widget.doctor.id,
          _selectedDate,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading appointments: ${snapshot.error}'),
              ),
            );
          }

          final appointments = snapshot.data ?? [];
          // Sort strictly by queue number (ascending)
          appointments.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));
          _latestAppointments = appointments;

          // Metrics calculation
          final totalBooked = appointments.length;
          final attendedCount = appointments
              .where((a) => a.status == AppointmentStatus.completed)
              .length;
          final paidAppointments = appointments
              .where((a) => a.status == AppointmentStatus.completed && a.paymentType == PaymentType.paid)
              .toList();
          final freeAppointments = appointments
              .where((a) =>
                  a.status == AppointmentStatus.completed &&
                  (a.paymentType == PaymentType.freeReview || a.paymentType == PaymentType.freeFamily))
              .toList();
          final absentCount = appointments
              .where((a) => a.status == AppointmentStatus.absent)
              .length;
          final waitingCount = appointments
              .where((a) => a.status == AppointmentStatus.pending)
              .length;

          final totalDoctorFees = paidAppointments.fold(0, (sum, a) => sum + a.amountCollected);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date Selector Header
                      _buildDateBar(),
                      const SizedBox(height: 16),

                      // Live KPI Metric Tiles
                      _buildMetricsGrid(
                        totalBooked: totalBooked,
                        attendedCount: attendedCount,
                        paidCount: paidAppointments.length,
                        freeCount: freeAppointments.length,
                        absentCount: absentCount,
                        waitingCount: waitingCount,
                        totalFees: totalDoctorFees,
                        isDesktop: isDesktop,
                      ),
                      const SizedBox(height: 24),

                      // Live Queue Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 20, color: Color(0xFF334155)),
                              const SizedBox(width: 8),
                              const Text(
                                "Today's Patient Queue",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "$totalBooked issued",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Live Sync",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Audit-Proof Token List
                      if (appointments.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: appointments.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                          itemBuilder: (ctx, index) {
                            return _buildTokenCard(appointments[index]);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => _changeDate(-1),
            tooltip: 'Previous Day',
          ),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    _isToday
                        ? 'Today (${DateFormat('dd MMM yyyy').format(_selectedDate)})'
                        : DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _changeDate(1),
            tooltip: 'Next Day',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid({
    required int totalBooked,
    required int attendedCount,
    required int paidCount,
    required int freeCount,
    required int absentCount,
    required int waitingCount,
    required int totalFees,
    required bool isDesktop,
  }) {
    final cards = [
      _MetricTile(
        title: "Total Tokens",
        value: "$totalBooked",
        subtitle: "$waitingCount still in queue",
        icon: Icons.confirmation_number_outlined,
        color: Colors.blue,
      ),
      _MetricTile(
        title: "Consulted",
        value: "$attendedCount",
        subtitle: "$paidCount paid • $freeCount free",
        icon: Icons.done_all_rounded,
        color: Colors.teal,
      ),
      _MetricTile(
        title: "Absent / No-Show",
        value: "$absentCount",
        subtitle: "Slots preserved",
        icon: Icons.person_off_outlined,
        color: const Color(0xFF64748B),
      ),
      _MetricTile(
        title: "Doctor Share",
        value: "₹$totalFees",
        subtitle: "From $paidCount paid visits",
        icon: Icons.currency_rupee_rounded,
        color: const Color(0xFF059669),
      ),
    ];


    if (isDesktop) {
      return Row(
        children: cards
            .map((card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: card,
                  ),
                ))
            .toList(),
      );
    } else {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
        children: cards,
      );
    }
  }

  Widget _buildTokenCard(Appointment appt) {
    Color badgeBg;
    Color badgeFg;
    String statusTitle;
    String paymentSubtitle;

    final isCallingNow = appt.id == _activeCallingApptId;

    if (isCallingNow) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeFg = const Color(0xFF15803D);
      statusTitle = "CALLING / IN CHAMBER";
      paymentSubtitle = "Active Token • In Chamber";
    } else if (appt.status == AppointmentStatus.absent) {
      badgeBg = const Color(0xFFF1F5F9);
      badgeFg = const Color(0xFF64748B);
      statusTitle = "ABSENT";
      paymentSubtitle = "Slot Preserved • ₹0";
    } else if (appt.status == AppointmentStatus.completed) {
      if (appt.paymentType == PaymentType.paid) {
        badgeBg = const Color(0xFFDCFCE7);
        badgeFg = const Color(0xFF15803D);
        statusTitle = "COMPLETED";
        paymentSubtitle = "Paid: ₹${appt.amountCollected}";
      } else if (appt.paymentType == PaymentType.freeReview) {
        badgeBg = const Color(0xFFFEF3C7);
        badgeFg = const Color(0xFFB45309);
        statusTitle = "FREE REVIEW";
        paymentSubtitle = "Follow-up / Report Check • ₹0";
      } else {
        badgeBg = const Color(0xFFEDE9FE);
        badgeFg = const Color(0xFF6D28D9);
        statusTitle = "FAMILY / COURTESY";
        paymentSubtitle = "Clinic Courtesy • ₹0";
      }
    } else {
      // Pending / In Queue
      badgeBg = const Color(0xFFE0F2FE);
      badgeFg = const Color(0xFF0369A1);
      statusTitle = "WAITING";
      paymentSubtitle = "In Waiting Room";
    }

    // Mask phone number for doctor view (e.g. +91 98*** 12345)
    final maskedPhone = _maskPhone(appt.patientPhone);

    return InkWell(
      onTap: appt.status != AppointmentStatus.absent ? () => _openConsultation(appt) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCallingNow ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCallingNow
                ? Colors.teal.shade600
                : (appt.status == AppointmentStatus.pending
                    ? Colors.blue.shade200
                    : const Color(0xFFE2E8F0)),
            width: isCallingNow ? 2.5 : (appt.status == AppointmentStatus.pending ? 1.5 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: isCallingNow
                  ? Colors.teal.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.015),
              blurRadius: isCallingNow ? 8 : 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Queue Number Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: appt.status == AppointmentStatus.absent
                    ? Colors.grey.shade100
                    : Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: appt.status == AppointmentStatus.absent
                      ? Colors.grey.shade300
                      : Colors.teal.shade200,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                "#${appt.queueNumber.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: appt.status == AppointmentStatus.absent
                      ? Colors.grey.shade600
                      : Colors.teal.shade800,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Patient Name & Masked Phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appt.patientName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: appt.status == AppointmentStatus.absent
                          ? Colors.grey.shade500
                          : const Color(0xFF0F172A),
                      decoration: appt.status == AppointmentStatus.absent
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    maskedPhone,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Status & Fee Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeFg,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  paymentSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: appt.amountCollected > 0 ? const Color(0xFF15803D) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            // 1-Click Consultation Encounter action
            if (appt.status != AppointmentStatus.absent) ...[
              const SizedBox(width: 14),
              if (appt.status == AppointmentStatus.pending)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Consult', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _openConsultation(appt),
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.description_outlined, size: 14),
                  label: const Text('Record', style: TextStyle(fontSize: 11)),
                  onPressed: () => _openConsultation(appt),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _openConsultation(Appointment appt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ConsultationEncounterScreen(
          appointment: appt,
          doctor: widget.doctor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 54, color: Colors.teal.shade200),
          const SizedBox(height: 16),
          const Text(
            "No appointments scheduled for this date",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Text(
            "When Sam books appointments at the reception desk, they appear here live.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    final last4 = phone.substring(phone.length - 4);
    final prefix = phone.substring(0, (phone.length - 4).clamp(0, 3));
    return '$prefix*****$last4';
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Chamber?'),
        content: const Text('Do you want to log out of this doctor chamber session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
