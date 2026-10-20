import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/clinic_provider.dart';

/// Offline fallback warning banner displayed inside booking dialogs when broadband connectivity is lost.
class BookingOfflineBanner extends StatelessWidget {
  const BookingOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOffline = context.select<ClinicProvider, bool>(
      (p) => p.isOfflineFallback,
    );
    if (!isOffline) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        children: const [
          Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFB45309),
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Broadband Offline (Viewing Local Cache). Booking tokens requires active cloud connection.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
