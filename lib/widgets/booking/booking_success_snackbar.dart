import 'package:flutter/material.dart';

import '../../config/clinic_config.dart';
import '../../models/appointment.dart';
import '../print/token_receipt_dialog.dart';

/// Helper to render the post-booking snackbar notification with optional print slip trigger.
class BookingSuccessSnackbar {
  static void show(BuildContext context, Appointment newAppt) {
    if (ClinicConfig.current.features.enableTokenReceiptPrint) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Token #${newAppt.queueNumber} booked for ${newAppt.patientName}',
          ),
          action: SnackBarAction(
            label: 'PRINT SLIP',
            textColor: const Color(0xFF5EEAD4),
            onPressed: () {
              TokenReceiptDialog.show(context, newAppt);
            },
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Token #${newAppt.queueNumber} booked for ${newAppt.patientName}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
