import 'dart:js_interop';

@JS('playClinicChime')
external void _playClinicChime(JSNumber? tokenNumber, JSString? doctorName);

void playChime({int? tokenNumber, String? doctorName}) {
  _playClinicChime(tokenNumber?.toJS, doctorName?.toJS);
}
