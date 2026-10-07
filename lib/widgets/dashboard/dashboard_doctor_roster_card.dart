import 'package:flutter/material.dart';

import '../../providers/clinic_provider.dart';
import '../../screens/doctor_list_screen.dart';

/// "Doctor Chamber Roster" panel displaying active consulting physicians and live token counts.
class DashboardDoctorRosterCard extends StatelessWidget {
  final ClinicProvider provider;

  const DashboardDoctorRosterCard({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
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
