import 'package:flutter/material.dart';

import '../../models/doctor.dart';
import '../../utils/formatters.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.teal.shade50,
              child: Text(
                doctor.name.isNotEmpty ? doctor.name[0] : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.teal.shade800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
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
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
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
                            border: Border.all(
                              color: Colors.amber.shade300,
                            ),
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
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              alignment: WrapAlignment.end,
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
            ),
          ],
        ),
      ),
    );
  }
}
