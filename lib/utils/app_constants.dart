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
}
