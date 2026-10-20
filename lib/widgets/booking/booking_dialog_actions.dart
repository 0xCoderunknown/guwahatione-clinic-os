import 'package:flutter/material.dart';

/// Modal dialog action buttons for walk-in and advance booking forms.
class BookingDialogActions extends StatelessWidget {
  final bool isBooking;
  final bool isLoading;
  final bool isDisabled;
  final FocusNode? submitFocusNode;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const BookingDialogActions({
    super.key,
    required this.isBooking,
    required this.isLoading,
    required this.isDisabled,
    this.submitFocusNode,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isBooking ? null : onCancel,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          focusNode: submitFocusNode,
          onPressed: (isDisabled || isLoading || isBooking) ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
          ),
          child: isBooking
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Booking Token...'),
                  ],
                )
              : isLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Searching Patient...'),
                  ],
                )
              : const Text('Book Appointment'),
        ),
      ],
    );
  }
}
