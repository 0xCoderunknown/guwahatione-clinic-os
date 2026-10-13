import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/appointment.dart';
import 'firestore_paths.dart';

/// Service responsible for persisting and retrieving daily appointment queues
/// locally to survive transient network dropouts and broadband interruptions.
class OfflineQueueCacheService {
  OfflineQueueCacheService._();

  static const String _prefix = 'offline_queue_';
  static const String _timePrefix = 'offline_queue_time_';

  static String _queueKey(DateTime date) =>
      '$_prefix${FirestorePaths.dateKey(date)}';

  static String _timeKey(DateTime date) =>
      '$_timePrefix${FirestorePaths.dateKey(date)}';

  /// Saves the daily appointment queue to local storage.
  static Future<void> saveQueue(
    DateTime date,
    List<Appointment> appointments, {
    SharedPreferences? prefs,
  }) async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    final jsonList = appointments.map((a) => a.toCacheMap()).toList();
    final encoded = jsonEncode(jsonList);
    final nowIso = DateTime.now().toIso8601String();

    await sp.setString(_queueKey(date), encoded);
    await sp.setString(_timeKey(date), nowIso);
  }

  /// Retrieves the cached appointment queue for a specific date, if present.
  static Future<List<Appointment>?> getCachedQueue(
    DateTime date, {
    SharedPreferences? prefs,
  }) async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    final raw = sp.getString(_queueKey(date));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Retrieves the timestamp when the cache for a date was last saved.
  static Future<DateTime?> getCacheTimestamp(
    DateTime date, {
    SharedPreferences? prefs,
  }) async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    final rawTime = sp.getString(_timeKey(date));
    if (rawTime == null || rawTime.isEmpty) return null;

    try {
      return DateTime.parse(rawTime);
    } catch (_) {
      return null;
    }
  }

  /// Clears cache for a given date.
  static Future<void> clearCache(
    DateTime date, {
    SharedPreferences? prefs,
  }) async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    await sp.remove(_queueKey(date));
    await sp.remove(_timeKey(date));
  }
}
