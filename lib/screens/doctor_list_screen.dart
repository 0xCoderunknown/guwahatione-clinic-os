import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clinic_provider.dart';
import 'add_doctor_screen.dart';

class DoctorListScreen extends StatelessWidget {
  const DoctorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctors')),
      body: Consumer<ClinicProvider>(
        builder: (context, provider, child) {
          final doctors = provider.doctors;
          if (doctors.isEmpty) {
            return const Center(child: Text('No doctors added yet.'));
          }
          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      doctor.name.isNotEmpty ? doctor.name[0] : '?',
                    ),
                  ),
                  title: Text(
                    doctor.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${doctor.specialty} • ${doctor.availableDays.join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
