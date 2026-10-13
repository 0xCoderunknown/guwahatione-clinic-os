import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/platform_sound.dart';

/// Service managing clinic lobby audio chime & vocal token announcements.
class SoundService extends ChangeNotifier {
  static const String _prefMutedKey = 'sound_announcer_muted';

  static final SoundService instance = SoundService._internal();

  SoundService._internal();

  // Test-friendly constructor
  SoundService.create({bool initialMuted = false, this.chimeTrigger})
      : _isMuted = initialMuted;

  void Function({int? tokenNumber, String? doctorName})? chimeTrigger;

  bool _isMuted = false;
  bool _isInitialized = false;
  String? _lastAnnouncedKey;

  bool get isMuted => _isMuted;
  bool get isInitialized => _isInitialized;
  String? get lastAnnouncedKey => _lastAnnouncedKey;

  /// Loads mute preference from SharedPreferences.
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool(_prefMutedKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing SoundService: $e');
    }
  }

  /// Toggles mute state and persists preference.
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefMutedKey, _isMuted);
    } catch (e) {
      debugPrint('Error saving mute state: $e');
    }
  }

  /// Sets mute state explicitly and persists preference.
  Future<void> setMuted(bool muted) async {
    if (_isMuted == muted) return;
    _isMuted = muted;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefMutedKey, _isMuted);
    } catch (e) {
      debugPrint('Error saving mute state: $e');
    }
  }

  /// Announces patient token to the clinic lobby if not muted.
  /// Skips duplicate announcements for the same [callKey].
  bool announceToken({
    required int tokenNumber,
    required String doctorName,
    String? callKey,
  }) {
    if (_isMuted) return false;

    if (callKey != null && _lastAnnouncedKey == callKey) {
      return false; // Skip duplicate trigger
    }

    _lastAnnouncedKey = callKey;

    if (chimeTrigger != null) {
      chimeTrigger!(tokenNumber: tokenNumber, doctorName: doctorName);
    } else {
      triggerClinicChime(tokenNumber: tokenNumber, doctorName: doctorName);
    }

    return true;
  }

  /// Resets session deduplication key (e.g. for testing or new day).
  void resetDeduplication() {
    _lastAnnouncedKey = null;
  }
}
