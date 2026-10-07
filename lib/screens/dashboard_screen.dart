import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/clinic_provider.dart';
import '../widgets/widgets.dart';
import 'add_appointment_dialog.dart';

/// Reception Dashboard Screen: live metrics, queue monitor, and doctor roster orchestrator.
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
                    DashboardHeaderBar(provider: provider),
                    const SizedBox(height: 20),

                    // 2. Responsive KPI Metrics Strip
                    DashboardKpiStrip(provider: provider, screenWidth: width),
                    const SizedBox(height: 24),

                    // 3. Quick Reception Action Chips
                    const DashboardQuickActionChips(),
                    const SizedBox(height: 24),

                    // 4. Content Area: Today's Live Queue & Doctor Roster
                    if (width >= 1050)
                      // Desktop: Side-by-side split panels
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: DashboardTodayQueueCard(provider: provider),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 4,
                            child: DashboardDoctorRosterCard(provider: provider),
                          ),
                        ],
                      )
                    else
                      // Mobile / Tablet: Stacked vertical flow
                      Column(
                        children: [
                          DashboardTodayQueueCard(provider: provider),
                          const SizedBox(height: 20),
                          DashboardDoctorRosterCard(provider: provider),
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
}
