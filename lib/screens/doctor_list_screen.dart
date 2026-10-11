import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/clinic_provider.dart';
import '../widgets/widgets.dart';
import 'add_doctor_screen.dart';
import 'doctor_chamber_screen.dart';

class DoctorListScreen extends StatelessWidget {
  const DoctorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    final canPop = Navigator.canPop(context);
    final showAppBar = !isDesktop || canPop;
    final isOwner = Provider.of<AuthProvider>(context).isOwner;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(
                isOwner ? 'Doctors & Chamber PINs' : 'Doctor Rosters & Schedules',
              ),
            )
          : null,
      body: Consumer<ClinicProvider>(
        builder: (context, provider, child) {
          final doctors = provider.doctors;
          if (doctors.isEmpty) {
            return const Center(child: Text('No doctors added yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return DoctorRosterCard(
                doctor: doctor,
                isOwner: isOwner,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddDoctorScreen(doctor: doctor),
                    ),
                  );
                },
                onChamberView: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorChamberScreen(
                        doctor: doctor,
                        isPreviewMode: true,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              backgroundColor: Colors.teal,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Doctor',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
