import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/engines/appointment_engine.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';

/// Warning banner displayed when an identical patient name/phone is already booked for today.
class BookingDuplicateWarningBanner extends StatelessWidget {
  final Appointment duplicate;

  const BookingDuplicateWarningBanner({
    super.key,
    required this.duplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Warm amber background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFB45309),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ ${duplicate.patientName} already holds Token #${duplicate.queueNumber} with ${AppFormatters.doctorTitle(duplicate.doctorName)} for today.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Modify Name if booking for a family member.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFB45309),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text('View Token #${duplicate.queueNumber}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF92400E),
                  side: const BorderSide(color: Color(0xFFD97706)),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                onPressed: () {
                  final prov = Provider.of<ClinicProvider>(
                    context,
                    listen: false,
                  );
                  prov.setDashboardSearchQuery('${duplicate.queueNumber}');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Viewing Token #${duplicate.queueNumber} • ${duplicate.patientName}',
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Warning banner displayed when booking on a date that is not normally in the doctor's roster.
class BookingOffDayWarningBanner extends StatelessWidget {
  final Doctor doctor;
  final DateTime date;

  const BookingOffDayWarningBanner({
    super.key,
    required this.doctor,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayName = dayNames[date.weekday - 1];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Warm amber background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.event_busy,
            color: Color(0xFFB45309),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚠️ ${AppFormatters.doctorTitle(doctor.name)} does not normally sit on ${dayName}s (Schedule: ${doctor.availableDays.join(", ")}). Booking is allowed if on special duty.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Warning banner displayed when booking on a date when the doctor is on planned leave.
class BookingDoctorLeaveWarningBanner extends StatelessWidget {
  final Doctor doctor;
  final DateTime date;

  const BookingDoctorLeaveWarningBanner({
    super.key,
    required this.doctor,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final leaveSummary = AppointmentEngine.formatDoctorLeaveSummary(
          doctor: doctor,
          date: date,
        ) ??
        'Doctor is on leave';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2), // Soft red / rose background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.block,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '🚫 $leaveSummary. Appointments cannot be booked on doctor leave dates.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF991B1B),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
