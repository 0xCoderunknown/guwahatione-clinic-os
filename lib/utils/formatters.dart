import 'package:intl/intl.dart';

/// Centralized date, time, and currency formatters for GuwahatiOne Clinic OS.
/// Ensures consistent presentation across all counters, chambers, and prints.
class AppFormatters {
  AppFormatters._();

  static final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd-MM-yyyy, hh:mm a');
  static final DateFormat _dateWithDayFormat = DateFormat('EEEE, dd-MM-yyyy');
  static final DateFormat _compactDateFormat = DateFormat('dd-MM-yy');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');

  /// Formats date to Indian format 'dd-MM-yyyy' (e.g., '07-10-2026'). Returns fallback if null.
  static String date(DateTime? dt, {String fallback = '—'}) {
    if (dt == null) return fallback;
    return _dateFormat.format(dt);
  }

  /// Formats time to 'hh:mm a' (e.g., '10:30 AM'). Returns fallback if null.
  static String time(DateTime? dt, {String fallback = '—'}) {
    if (dt == null) return fallback;
    return _timeFormat.format(dt);
  }

  /// Formats date and time to 'dd-MM-yyyy, hh:mm a' (e.g., '07-10-2026, 10:30 AM'). Returns fallback if null.
  static String dateTime(DateTime? dt, {String fallback = '—'}) {
    if (dt == null) return fallback;
    return _dateTimeFormat.format(dt);
  }

  /// Formats date with weekday to 'EEEE, dd-MM-yyyy' (e.g., 'Wednesday, 07-10-2026').
  static String dateWithDay(DateTime? dt, {String fallback = '—'}) {
    if (dt == null) return fallback;
    return _dateWithDayFormat.format(dt);
  }

  /// Formats compact Indian date to 'dd-MM-yy' (e.g., '07-10-26').
  static String compactDate(DateTime? dt, {String fallback = '—'}) {
    if (dt == null) return fallback;
    return _compactDateFormat.format(dt);
  }

  /// Formats ISO date string 'yyyy-MM-dd' for Firestore counter query keys.
  static String isoDate(DateTime? dt) {
    if (dt == null) return '';
    return _isoDateFormat.format(dt);
  }

  /// Formats Indian Rupee currency (e.g., '₹500').
  static String currency(num? amount) {
    if (amount == null) return '₹0';
    if (amount % 1 == 0) {
      return '₹${amount.toInt()}';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Formats doctor title preventing duplicate "Dr. Dr." prefixes.
  static String doctorTitle(String? name) {
    if (name == null || name.trim().isEmpty) return 'Doctor';
    final clean = name.trim();
    var stripped = clean;
    while (stripped.toLowerCase().startsWith('dr.') || stripped.toLowerCase().startsWith('dr ')) {
      stripped = stripped.replaceFirst(RegExp(r'^dr\.?\s*', caseSensitive: false), '').trim();
    }
    return 'Dr. $stripped';
  }

  /// Sanitizes specialty and corrects common typos like 'Paedetric' -> 'Paediatric'.
  static String specialty(String? specialty) {
    if (specialty == null || specialty.trim().isEmpty) return 'General';
    var clean = specialty.trim();
    clean = clean.replaceAll(RegExp(r'paedetric', caseSensitive: false), 'Paediatric');
    return clean;
  }

  /// Extracts compact doctor initials (e.g. 'Dr. Bhaskar Thakuria' -> 'BT').
  static String doctorInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final clean = name
        .trim()
        .replaceFirst(RegExp(r'^dr\.?\s*', caseSensitive: false), '')
        .trim();
    if (clean.isEmpty) return 'DR';
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    final first = parts.first[0].toUpperCase();
    final last = parts.last[0].toUpperCase();
    return '$first$last';
  }
}

