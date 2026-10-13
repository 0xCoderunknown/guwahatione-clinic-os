import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/clinic_provider.dart';
import '../services/sound_service.dart';
import '../widgets/widgets.dart';
import 'appointment_list_screen.dart';
import 'dashboard_screen.dart';
import 'doctor_list_screen.dart';
import 'medicine_catalogue_screen.dart';
import 'statistics_screen.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _selectedIndex = 0;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isOwner) {
      // 5-minute background auto step-down timer
      _inactivityTimer = Timer(const Duration(minutes: 5), () {
        if (mounted && auth.isOwner) {
          auth.stepDownToReception();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '🔒 Inactivity timeout: Session locked to Reception.',
              ),
              backgroundColor: Colors.amber,
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    final isOwner = auth.isOwner;

    // Build role-guarded pages and destinations
    final List<Widget> pages = [
      const DashboardScreen(),
      const AppointmentListScreen(),
      const DoctorListScreen(),
      if (isOwner) const StatisticsScreen(),
      const MedicineCatalogueScreen(),
    ];

    final List<NavigationRailDestination> desktopDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard, color: Colors.teal),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.calendar_today_outlined),
        selectedIcon: Icon(Icons.calendar_today, color: Colors.teal),
        label: Text('Appointments'),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.people_alt_outlined),
        selectedIcon: const Icon(Icons.people_alt, color: Colors.teal),
        label: Text(isOwner ? 'Doctors & PINs' : 'Doctor Schedules'),
      ),
      if (isOwner)
        const NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: Colors.teal),
          label: Text('Revenue & Audit'),
        ),
      const NavigationRailDestination(
        icon: Icon(Icons.medication_outlined),
        selectedIcon: Icon(Icons.medication, color: Colors.teal),
        label: Text('Medicine Catalog'),
      ),
    ];

    final List<NavigationDestination> mobileDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_today_outlined),
        selectedIcon: Icon(Icons.calendar_today),
        label: 'Queue',
      ),
      NavigationDestination(
        icon: const Icon(Icons.people_alt_outlined),
        selectedIcon: const Icon(Icons.people_alt),
        label: isOwner ? 'Doctors' : 'Schedules',
      ),
      if (isOwner)
        const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Revenue',
        ),
      const NavigationDestination(
        icon: Icon(Icons.medication_outlined),
        selectedIcon: Icon(Icons.medication),
        label: 'Catalogue',
      ),
    ];

    // Ensure selected index is within bounds when stepping down
    final safeIndex = _selectedIndex < pages.length ? _selectedIndex : 0;

    return Listener(
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      child: isDesktop
          ? _buildDesktopShell(
              context,
              auth,
              safeIndex,
              pages,
              desktopDestinations,
            )
          : _buildMobileShell(context, safeIndex, pages, mobileDestinations),
    );
  }

  Widget _buildDesktopShell(
    BuildContext context,
    AuthProvider auth,
    int selectedIndex,
    List<Widget> pages,
    List<NavigationRailDestination> destinations,
  ) {
    final isOwner = auth.isOwner;

    return Scaffold(
      body: Row(
        children: [
          // Desktop Sidebar Navigation Rail
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
              _resetInactivityTimer();
            },
            minWidth: 72,
            minExtendedWidth: 220,
            extended: MediaQuery.of(context).size.width >= 1100,
            backgroundColor: Colors.white,
            elevation: 1,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isOwner
                          ? Colors.amber.shade50
                          : Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isOwner
                          ? Icons.admin_panel_settings_rounded
                          : Icons.local_hospital_rounded,
                      color: isOwner
                          ? Colors.amber.shade800
                          : Colors.teal.shade700,
                      size: 24,
                    ),
                  ),
                  if (MediaQuery.of(context).size.width >= 1100) ...[
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GuwahatiOne',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          isOwner ? '👑 Clinic Owner' : 'Reception Desk',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isOwner
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isOwner
                                ? Colors.amber.shade900
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                    ),
                    tooltip: isOwner ? 'Logout (Owner)' : 'Logout of Reception',
                    onPressed: () => _confirmLogout(context),
                  ),
                ),
              ),
            ),
            destinations: destinations,
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: Color(0xFFE2E8F0),
          ),

          // Main Content Area
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0.5,
                title: Row(
                  children: [
                    Text(
                      _getTitleForIndex(selectedIndex, isOwner),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),

                    // Step-Down Security Button for Owner
                    if (isOwner) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber.shade900,
                          backgroundColor: Colors.amber.shade50,
                          side: BorderSide(color: Colors.amber.shade400),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () {
                          auth.stepDownToReception();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '🔒 Session locked to Reception Desk. Master controls secured.',
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.lock_outline, size: 16),
                        label: const Text(
                          'Lock to Reception',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],

                    // Lobby Waiting Badge
                    Consumer<ClinicProvider>(
                      builder: (_, clinic, _) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.hourglass_top_rounded,
                              size: 14,
                              color: Colors.amber.shade800,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Lobby: ${clinic.waitingCount} Waiting",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Lobby Sound Announcer Toggle
                    Consumer<SoundService>(
                      builder: (_, sound, _) => Tooltip(
                        message: sound.isMuted
                            ? 'Lobby Announcer Muted (Click to Unmute)'
                            : 'Lobby Announcer Active (Click to Mute)',
                        child: InkWell(
                          onTap: () => sound.toggleMute(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: sound.isMuted
                                  ? Colors.grey.shade100
                                  : Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sound.isMuted
                                    ? Colors.grey.shade300
                                    : Colors.teal.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  sound.isMuted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  size: 15,
                                  color: sound.isMuted
                                      ? Colors.grey.shade600
                                      : Colors.teal.shade800,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  sound.isMuted ? 'Muted' : 'Chime On',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: sound.isMuted
                                        ? Colors.grey.shade700
                                        : Colors.teal.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Primary Single Walk-In Patient Entry Point
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const AddAppointmentDialog(),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Book Walk-In Patient'),
                    ),
                  ],
                ),
              ),
              body: pages[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileShell(
    BuildContext context,
    int selectedIndex,
    List<Widget> pages,
    List<NavigationDestination> destinations,
  ) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
          _resetInactivityTimer();
        },
        destinations: destinations,
      ),
    );
  }

  String _getTitleForIndex(int index, bool isOwner) {
    if (isOwner) {
      switch (index) {
        case 0:
          return 'Overview Dashboard';
        case 1:
          return 'Live Appointment Queue';
        case 2:
          return 'Doctors & Chamber PINs';
        case 3:
          return 'Financial Ledger & Audit';
        case 4:
          return 'Master Medicine Catalogue';
        default:
          return 'GuwahatiOne Clinic';
      }
    } else {
      switch (index) {
        case 0:
          return 'Overview Dashboard';
        case 1:
          return 'Live Appointment Queue';
        case 2:
          return 'Doctor Schedules (Read-Only)';
        case 3:
          return 'Master Medicine Catalogue';
        default:
          return 'GuwahatiOne Clinic';
      }
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout of Reception?'),
        content: const Text(
          'Are you sure you want to end this counter session?',
        ),
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
