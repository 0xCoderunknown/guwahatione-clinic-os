/// Non-web fallback stub for platform file download.
void downloadFile({
  required String filename,
  required String content,
  String mimeType = 'text/csv;charset=utf-8;',
}) {
  // No-op on non-web platforms without direct file saver plugins
}
