import 'dart:async';

enum SyncErrorCategory {
  dnsNetwork,
  timeout,
  authPairing,
  tlsCert,
  httpStatus,
  unknown,
}

SyncErrorCategory classifySyncError(Object error) {
  if (error is TimeoutException) {
    return SyncErrorCategory.timeout;
  }

  final text = error.toString().toLowerCase();

  if (_containsAny(text, const [
    'failed host lookup',
    'socketexception',
    'connection refused',
    'network is unreachable',
    'connection reset by peer',
    'os error',
  ])) {
    return SyncErrorCategory.dnsNetwork;
  }

  if (_containsAny(text, const ['timed out', 'timeout'])) {
    return SyncErrorCategory.timeout;
  }

  if (_containsAny(text, const [
    'pairing required',
    'http 401',
    'http 403',
    'unauthorized',
    'forbidden',
    'invalid token',
  ])) {
    return SyncErrorCategory.authPairing;
  }

  if (_containsAny(text, const [
    'handshakeexception',
    'certificate',
    'cert ',
    'x509',
    'tls',
  ])) {
    return SyncErrorCategory.tlsCert;
  }

  if (RegExp(r'http\s*\d{3}').hasMatch(text) || text.contains('status code')) {
    return SyncErrorCategory.httpStatus;
  }

  return SyncErrorCategory.unknown;
}

String errorMessage(SyncErrorCategory category) {
  switch (category) {
    case SyncErrorCategory.dnsNetwork:
      return 'Cannot reach desktop server. Check Wi-Fi/LAN and server address.';
    case SyncErrorCategory.timeout:
      return 'Sync timed out. Keep app open; it will retry on the next cycle.';
    case SyncErrorCategory.authPairing:
      return 'Pairing/auth issue. Re-pair phone with desktop in Settings.';
    case SyncErrorCategory.tlsCert:
      return 'TLS certificate not trusted. Approve/update the server certificate.';
    case SyncErrorCategory.httpStatus:
      return 'Server rejected sync request. Verify desktop server health and logs.';
    case SyncErrorCategory.unknown:
      return 'Sync failed unexpectedly. It will retry on the next cycle.';
  }
}

bool _containsAny(String value, List<String> needles) {
  for (final needle in needles) {
    if (value.contains(needle)) {
      return true;
    }
  }
  return false;
}
