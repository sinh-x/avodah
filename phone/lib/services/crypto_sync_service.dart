/// Platform transport: native TLS approval stays native; browsers use trusted
/// same-origin HTTPS and never bypass certificate validation.
library;

export 'crypto_sync_native.dart'
    if (dart.library.js_interop) 'crypto_sync_web.dart';
