import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

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
              content: Text('🔒 Session locked to reception after inactivity.'),
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
      const PatientDirectoryScreen(),
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
      const NavigationRailDestination(
        icon: Icon(Icons.person_search_outlined),
        selectedIcon: Icon(Icons.person_search, color: Colors.teal),
        label: Text('Patients'),
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
      const NavigationDestination(
        icon: Icon(Icons.person_search_outlined),
        selectedIcon: Icon(Icons.person_search),
        label: 'Patients',
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
              : _buildMobileShell(
                  context,
                  safeIndex,
                  pages,
                  mobileDestinations,
                ),
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
              appBar: OwnerShellAppBar(
                selectedIndex: selectedIndex,
                isOwner: isOwner,
                onWalkInBooking: () => _openWalkInBooking(context),
                onStepDown: () {
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
    // Show prominent floating booking trigger on reception operational views (Dashboard = 0, Queue = 1)
    final showFab = selectedIndex == 0 || selectedIndex == 1;

    return Scaffold(
      body: pages[selectedIndex],
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              key: const Key('mobile_book_walkin_fab'),
              onPressed: () => _openWalkInBooking(context),
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Book Walk-In',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            )
          : null,
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
