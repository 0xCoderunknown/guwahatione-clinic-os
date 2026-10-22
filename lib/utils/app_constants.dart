class AppConstants {
  /// Globally blocked dates (clinic holidays).
  ///
  /// NOTE: Internal comparison format is ISO 'YYYY-MM-DD' for programmatic checks only.
  /// This is distinct from the mandatory 'DD-MM-YYYY' display format used everywhere else in the product.
  static const List<String> blockedDates = [
    // Add clinic holiday dates in ISO format here, e.g.:
    // '2026-10-02',  // Gandhi Jayanti (02-10-2026)
  ];

  static bool isDateBlocked(DateTime date) {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return blockedDates.contains(dateString);
  }

  // ---------------------------------------------------------------------------
  // Clinical Input Length Limits (AUDIT-21)
  // Generous caps to prevent paste explosions and preserve letterhead layout.
  // ---------------------------------------------------------------------------
  static const int maxComplaintLength = 150;
  static const int maxDiagnosisLength = 200;
  static const int maxExamNotesLength = 2000;
  static const int maxAdviceNotesLength = 2000;
  static const int maxAllergyLength = 100;
  static const int maxLabOrderLength = 150;
  static const int maxLabResultLength = 200;
}
