import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/clinic_provider.dart';
import '../services/sound_service.dart';
import '../utils/formatters.dart';
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
                '🔒 Session locked to reception after inactivity.',
              ),
              backgroundColor: Colors.amber,
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
    }
  }

  void _openWalkInBooking(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddAppointmentDialog(),
    );
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
          label: Text('Revenue & Records'),
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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f2): () =>
            _openWalkInBooking(context),
      },
      child: Focus(
        autofocus: true,
        child: Listener(
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
        ),
      ),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getTitleForIndex(selectedIndex, isOwner),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (selectedIndex == 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '•  ${AppFormatters.dateWithDay(DateTime.now())}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (selectedIndex == 0)
                          const Text(
                            'OPD Consultation Chamber & Reception Desk',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
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

                    // End-of-Day Cash Handover Button (Subtle Outline / Ghost)
                    Consumer<ClinicProvider>(
                      builder: (_, clinic, _) => Tooltip(
                        message:
                            'End-of-Day Cash Handover & Note Reconciliation',
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () =>
                              DailyCashHandoverDialog.show(context, clinic),
                          icon: const Icon(
                            Icons.receipt_long_rounded,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                          label: const Text(
                            'Cash Handover',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Lobby Sound Announcer Toggle (Compact Icon Button)
                    Consumer<SoundService>(
                      builder: (_, sound, _) => Tooltip(
                        message: sound.isMuted
                            ? 'Lobby Announcer Muted (Click to Unmute)'
                            : 'Lobby Announcer Active (Click to Mute)',
                        child: IconButton(
                          onPressed: () => sound.toggleMute(),
                          icon: Icon(
                            sound.isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            size: 19,
                            color: sound.isMuted
                                ? const Color(0xFF94A3B8)
                                : Colors.teal.shade700,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: sound.isMuted
                                ? const Color(0xFFF1F5F9)
                                : Colors.teal.shade50,
                            side: BorderSide(
                              color: sound.isMuted
                                  ? const Color(0xFFE2E8F0)
                                  : Colors.teal.shade200,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                            minimumSize: const Size(36, 36),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Primary Single Walk-In Patient Entry Point (Hotkey: F2)
                    Tooltip(
                      message: 'Register Walk-In Patient (Hotkey: F2)',
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _openWalkInBooking(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Book Walk-In',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '(F2)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
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
          return 'Payments & Reports';
        case 4:
          return 'Medicine Catalogue';
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
          return 'Medicine Catalogue';
        default:
          return 'GuwahatiOne Clinic';
      }
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End reception session?'),
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
