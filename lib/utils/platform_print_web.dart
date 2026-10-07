import 'dart:js_interop';

@JS('print')
external void _print();

void triggerBrowserPrint() {
  _print();
}
