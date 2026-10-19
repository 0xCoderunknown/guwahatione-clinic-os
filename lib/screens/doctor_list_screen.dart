import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/clinic_provider.dart';
import '../utils/formatters.dart';
import 'screens.dart';

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
                isOwner
                    ? 'Doctors & Chamber PINs'
                    : 'Doctor Rosters & Schedules',
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

/// Card displaying doctor profile details, specialty, fee, available schedule,
/// chamber PIN badge (for owner), and navigation action triggers.
class DoctorRosterCard extends StatelessWidget {
  final Doctor doctor;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onChamberView;

  const DoctorRosterCard({
    super.key,
    required this.doctor,
    required this.isOwner,
    this.onEdit,
    this.onChamberView,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final actionButtons = Wrap(
      alignment: isMobile ? WrapAlignment.start : WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        if (isOwner)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.teal,
              side: const BorderSide(color: Colors.teal),
            ),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
          ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.teal,
            side: const BorderSide(color: Colors.teal),
          ),
          onPressed: onChamberView,
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('Chamber View'),
        ),
      ],
    );

    final doctorInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppFormatters.doctorTitle(doctor.name),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${AppFormatters.specialty(doctor.specialty)} • Fee: ₹${doctor.consultationFee}',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (isOwner)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.key,
                      size: 12,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Chamber PIN: ${doctor.pin}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            if (doctor.medicalRegNumber != null &&
                doctor.medicalRegNumber!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 12,
                      color: Colors.teal.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Registration No. ${doctor.medicalRegNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: doctor.freeReviewDays > 0
                    ? Colors.blue.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: doctor.freeReviewDays > 0
                      ? Colors.blue.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_repeat,
                    size: 12,
                    color: doctor.freeReviewDays > 0
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    doctor.freeReviewDays > 0
                        ? 'Review: ${doctor.freeReviewDays}d'
                        : 'No Free Review',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: doctor.freeReviewDays > 0
                          ? Colors.blue.shade900
                          : Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              doctor.availableDays.join(', '),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.teal.shade50,
                        child: Text(
                          AppFormatters.doctorInitials(doctor.name),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: doctorInfo),
                    ],
                  ),
                  const SizedBox(height: 12),
                  actionButtons,
                ],
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.teal.shade50,
                    child: Text(
                      AppFormatters.doctorInitials(doctor.name),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: doctorInfo),
                  const SizedBox(width: 8),
                  actionButtons,
                ],
              ),
      ),
    );
  }
}
