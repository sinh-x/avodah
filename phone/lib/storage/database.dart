// Platform-conditional database opening for the Avodah phone viewer.
//
// Uses conditional imports to select the appropriate implementation:
// - `database_native.dart` for mobile/desktop (dart:io)
// - `database_web.dart` for web (dart:js_interop)
export 'database_native.dart' if (dart.library.js_interop) 'database_web.dart';
