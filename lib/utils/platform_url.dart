import 'platform_url_stub.dart'
    if (dart.library.js_interop) 'platform_url_web.dart';

/// Opens an external URL (e.g. WhatsApp deep link) in a new browser tab or system launcher.
void openUrl(String url) {
  openBrowserUrl(url);
}
