import 'dart:js_interop';

@JS('printHtmlDocument')
external void _printHtml(JSString html);

@JS('print')
external void _print();

void triggerBrowserPrint({String? html}) {
  if (html != null && html.isNotEmpty) {
    try {
      _printHtml(html.toJS);
      return;
    } catch (_) {
      // Fallback to window.print if iframe helper is unavailable
    }
  }
  _print();
}

