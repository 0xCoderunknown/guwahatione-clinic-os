import 'platform_sound_stub.dart'
    if (dart.library.js_interop) 'platform_sound_web.dart';

/// Triggers the clinic lobby audio chime and vocal token callout.
void triggerClinicChime({int? tokenNumber, String? doctorName}) {
  playChime(tokenNumber: tokenNumber, doctorName: doctorName);
}
