import 'package:flutter/material.dart';

import '../../core/engines/appointment_engine.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';

/// Doctor filter chip toolbar displayed above the reception queue table.
class QueueDoctorFilterBar extends StatelessWidget {
  final List<Doctor> doctors;
  final String? selectedDoctorId;
  final List<Appointment> todayAppointments;
  final ValueChanged<String?> onDoctorSelected;

  const QueueDoctorFilterBar({
    super.key,
    required this.doctors,
    required this.selectedDoctorId,
    required this.todayAppointments,
    required this.onDoctorSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (doctors.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              selected: selectedDoctorId == null,
              label: Text(
                'All Doctors (${todayAppointments.length})',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selectedDoctorId == null
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: selectedDoctorId == null
                      ? Colors.white
                      : const Color(0xFF334155),
                ),
              ),
              onSelected: (_) => onDoctorSelected(null),
              selectedColor: Colors.teal.shade700,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: selectedDoctorId == null
                    ? Colors.teal.shade700
                    : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(width: 8),
            ...doctors.map((doc) {
              final count = AppointmentEngine.countDoctorAppointments(
                appointments: todayAppointments,
                doctorId: doc.id,
              );
              final isSelected = selectedDoctorId == doc.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(
                    '${doc.titleName} ($count)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  onSelected: (_) => onDoctorSelected(doc.id),
                  selectedColor: Colors.teal.shade700,
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? Colors.teal.shade700
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
