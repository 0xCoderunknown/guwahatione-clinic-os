import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/clinic_provider.dart';
import '../utils/formatters.dart';
import '../widgets/widgets.dart';
import 'add_appointment_dialog.dart';
import 'appointment_list_screen.dart';
import 'doctor_list_screen.dart';
import 'statistics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClinicProvider>(context, listen: false)
          .startListeningToAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // On desktop, OwnerShell already provides a unified AppBar.
      // On mobile / tablet, show a sleek single AppBar.
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(
                'GuwahatiOne Clinic',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              centerTitle: false,
              elevation: 0.5,
              backgroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  tooltip: 'Logout',
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                ),
              ],
            ),
      body: Consumer<ClinicProvider>(
        builder: (context, provider, child) {
          return Center(
            child: ConstrainedBox(
              // Prevents cartoonish stretching on 23" FHD desktop monitors
              constraints: const BoxConstraints(maxWidth: 1400),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24.0 : 16.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Clinic Date & Quick Greeting Bar
                    _buildHeaderBar(context, provider),
                    const SizedBox(height: 20),

                    // 2. Responsive KPI Metrics Strip (Sleek cards, NOT giant blocks)
                    _buildResponsiveKpiStrip(context, provider, width),
                    const SizedBox(height: 24),

                    // 3. Quick Reception Action Chips
                    _buildQuickActionChips(context),
                    const SizedBox(height: 24),

                    // 4. Content Area: Today's Live Queue & Doctor Roster
                    if (width >= 1050)
                      // Desktop / 14" Laptop: Side-by-side split panels
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildTodayQueueCard(context, provider),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 4,
                            child: _buildDoctorRosterCard(context, provider),
                          ),
                        ],
                      )
                    else
                      // Mobile / Tablet: Stacked vertical flow
                      Column(
                        children: [
                          _buildTodayQueueCard(context, provider),
                          const SizedBox(height: 20),
                          _buildDoctorRosterCard(context, provider),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AddAppointmentDialog(),
          );
        },
        label: const Text(
          'Book Walk-In',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
        backgroundColor: Colors.teal.shade700,
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context, ClinicProvider provider) {
    final todayStr = AppFormatters.dateWithDay(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.today_rounded, color: Colors.teal.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayStr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    'OPD Consultation Chamber & Reception Desk',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_rupee, size: 14, color: Colors.green),
                    const SizedBox(width: 2),
                    Text(
                      "₹${provider.dailyRevenue}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "collected today",
                      style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveKpiStrip(
    BuildContext context,
    ClinicProvider provider,
    double screenWidth,
  ) {
    final completedCount = provider.todayAppointments
        .where((a) => a.status == AppointmentStatus.completed)
        .length;

    final cards = [
      _KpiItem(
        title: 'Today Appointments',
        value: '${provider.todayAppointments.length}',
        subtitle: '$completedCount completed',
        icon: Icons.calendar_today_rounded,
        color: const Color(0xFF2563EB), // Blue
        bgColor: const Color(0xFFEFF6FF),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
        ),
      ),
      _KpiItem(
        title: 'Realized Revenue',
        value: '₹${provider.dailyRevenue}',
        subtitle: 'From completed visits',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF059669), // Green
        bgColor: const Color(0xFFECFDF5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatisticsScreen()),
        ),
      ),
      _KpiItem(
        title: 'Waiting Patients',
        value: '${provider.pendingCount}',
        subtitle: 'Awaiting doctor consultation',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFD97706), // Amber
        bgColor: const Color(0xFFFFFBEB),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
        ),
      ),
      _KpiItem(
        title: 'Consulting Doctors',
        value: '${provider.doctors.length}',
        subtitle: 'Active OPD chambers',
        icon: Icons.medical_services_rounded,
        color: const Color(0xFF7C3AED), // Purple
        bgColor: const Color(0xFFF5F3FF),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DoctorListScreen()),
        ),
      ),
    ];

    if (screenWidth >= 900) {
      // Desktop / 14" Laptop: 4 columns in a sleek horizontal row
      return Row(
        children: cards.map((item) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: _buildMetricCard(item),
            ),
          );
        }).toList(),
      );
    } else {
      // Mobile / Tablet: 2x2 compact grid with healthy aspect ratio (1.6)
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (ctx, i) => _buildMetricCard(cards[i]),
      );
    }
  }

  Widget _buildMetricCard(_KpiItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 22, color: item.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: item.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChips(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.add_circle_outline, size: 16, color: Colors.teal),
          label: const Text('Book Walk-In Patient'),
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const AddAppointmentDialog(),
            );
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.format_list_numbered, size: 16, color: Color(0xFF2563EB)),
          label: const Text('View Full Token Queue'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF7C3AED)),
          label: const Text('Doctor Chamber PINs'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DoctorListScreen()),
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.bar_chart_outlined, size: 16, color: Color(0xFF059669)),
          label: const Text('Financial Audit & Payouts'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayQueueCard(BuildContext context, ClinicProvider provider) {
    final list = provider.todayAppointments;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.queue_play_next_rounded, size: 20, color: Color(0xFF0F172A)),
                const SizedBox(width: 10),
                const Text(
                  "Today's Live Queue",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
                  ),
                  child: const Text('Manage Queue →', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available_rounded, size: 44, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text(
                      'No appointments registered yet today',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "+ Book Walk-In Patient" to assign the first token.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.take(8).length,
              separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, i) {
                final appt = list[i];
                return ListTile(
                  dense: true,
                  leading: TokenBadge(
                    queueNumber: appt.queueNumber,
                    size: 34,
                    isCompleted: appt.status == AppointmentStatus.completed,
                    isAbsent: appt.status == AppointmentStatus.absent,
                  ),
                  title: Row(
                    children: [
                      Text(
                        appt.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${appt.patientPhone})',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    "Doctor: ${appt.doctorName} • Fee: ${AppFormatters.currency(appt.amountCollected)} (${appt.paymentType.displayName})",
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: appt.status == AppointmentStatus.pending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.record_voice_over_rounded, size: 14),
                              label: const Text('Call In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                await provider.callTokenIntoChamber(
                                  doctorId: appt.doctorId,
                                  date: appt.scheduledDate,
                                  appointment: appt,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Called Token #${appt.queueNumber} (${appt.patientName}) to Dr. ${appt.doctorName} chamber'),
                                      backgroundColor: Colors.teal.shade800,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            AppointmentStatusChip(status: appt.status, isCompact: true),
                          ],
                        )
                      : AppointmentStatusChip(status: appt.status, isCompact: true),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorRosterCard(BuildContext context, ClinicProvider provider) {
    final doctors = provider.doctors;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.meeting_room_outlined, size: 20, color: Color(0xFF0F172A)),
                const SizedBox(width: 10),
                const Text(
                  'Doctor Chamber Roster',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorListScreen()),
                  ),
                  child: const Text('Manage PINs →', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          if (doctors.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Center(
                child: Text(
                  'No consulting doctors registered yet.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: doctors.length,
              separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, i) {
                final doc = doctors[i];
                final patientCount = provider.todayAppointments
                    .where((a) => a.doctorId == doc.id)
                    .length;

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      doc.name.isNotEmpty ? doc.name[0].toUpperCase() : 'D',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                  ),
                  title: Text(
                    "Dr. ${doc.name}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    "${doc.specialty} • Fee: ₹${doc.consultationFee}",
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$patientCount tokens",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _KpiItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _KpiItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}
