class AppConstants {
  /// Default consultation fee (₹). Used for PaymentType.paid.
  /// Update this constant when the fee changes — it is referenced
  /// in all booking and status-update logic.
  static const int defaultConsultationFee = 500;

  /// Globally blocked dates (clinic holidays).
  /// Format: 'YYYY-MM-DD'. Add dates here to prevent bookings on those days.
  static const List<String> blockedDates = [
    // Add clinic holiday dates here, e.g.:
    // '2026-10-02',  // Gandhi Jayanti
  ];

  static bool isDateBlocked(DateTime date) {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return blockedDates.contains(dateString);
  }
}
