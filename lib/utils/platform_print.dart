import 'platform_print_stub.dart'
    if (dart.library.js_interop) 'platform_print_web.dart';

void printDocument() {
  triggerBrowserPrint();
}
