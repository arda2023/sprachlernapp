// The schema and validation code share SQLite's API on native and browser.
export 'sqlite_native.dart' if (dart.library.js_interop) 'sqlite_web.dart';
