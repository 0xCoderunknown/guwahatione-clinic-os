import 'dart:js_interop';

@JS('downloadTextFile')
external void _downloadTextFile(
  JSString filename,
  JSString content,
  JSString mimeType,
);

/// Web implementation using window.downloadTextFile via dart:js_interop.
void downloadFile({
  required String filename,
  required String content,
  String mimeType = 'text/csv;charset=utf-8;',
}) {
  _downloadTextFile(filename.toJS, content.toJS, mimeType.toJS);
}
