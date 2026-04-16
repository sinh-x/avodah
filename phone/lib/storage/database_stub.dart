import 'package:avodah_core/avodah_core.dart';

import 'phone_database.dart';

/// Stub for platform-specific database opening.
///
/// This file is used as a fallback when neither native nor web
/// platform detection succeeds. In practice, this should never
/// be called on a supported platform.
Future<AppDatabase> openPhoneDatabase() async {
  throw UnsupportedError(
    'Cannot open database: no platform implementation available. '
    'Use database_native.dart for mobile/desktop or '
    'database_web.dart for web.',
  );
}

/// Stub for phone-local database opening.
Future<PhoneDatabase> openPhoneLocalDatabase() async {
  throw UnsupportedError(
    'Cannot open phone-local database: no platform implementation available. '
    'Use database_native.dart for mobile/desktop.',
  );
}
