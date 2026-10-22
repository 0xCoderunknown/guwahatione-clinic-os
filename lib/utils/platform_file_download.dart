import 'platform_file_download_stub.dart'
    if (dart.library.js_interop) 'platform_file_download_web.dart';

/// Downloads a text file (such as CSV or JSON) directly in the browser
/// or handles platform-specific saving.
void downloadPlatformFile({
  required String filename,
  required String content,
  String mimeType = 'text/csv;charset=utf-8;',
}) {
  downloadFile(filename: filename, content: content, mimeType: mimeType);
}
