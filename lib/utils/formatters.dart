import 'package:intl/intl.dart';

/// Centralized date, time, and currency formatters for GuwahatiOne Clinic OS.
/// Ensures consistent presentation across all counters, chambers, and prints.
class AppFormatters {
  AppFormatters._();

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _dateWithDayFormat = DateFormat('EEEE, dd MMM yyyy');
  static final DateFormat _compactDateFormat = DateFormat('dd/MM/yy');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');

  /// Formats date to 'dd MMM yyyy' (e.g., '07 Oct 2026'). Returns fallback if null.
  static String date(DateTime? dt, {String fallback = '—'}) {
    if (dt == null) return fallback;
    return _dateFormat.format(dt);
  }

  /// Formats time to 'hh:mm a' (e.g., '10:30 AM'). Returns fallback if null.
  static String time(DateTime? dt, {String fallback = '—'}) {
    if (dt == null) return fallback;
    return _timeFormat.format(dt);
  }

  /// Formats date and time to 'dd MMM yyyy, hh:mm a'. Returns fallback if null.
  static String dateTime(DateTime? dt, {String fallback = '—'}) {
    if (dt == null) return fallback;
    return _dateTimeFormat.format(dt);
  }

  /// Formats date with weekday to 'EEEE, dd MMM yyyy' (e.g., 'Wednesday, 07 Oct 2026').
  static String dateWithDay(DateTime? dt, {String fallback = '—'}) {
    if (dt == null) return fallback;
    return _dateWithDayFormat.format(dt);
  }

  /// Formats compact date to 'dd/MM/yy' (e.g., '07/10/26').
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
}
