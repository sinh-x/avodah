import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Key pair for X25519 key exchange
class KeyPair {
  final List<int> publicKey;
  final List<int> privateKey;

  KeyPair({required this.publicKey, required this.privateKey});
}

/// Derives a pairing key from the shared secret using HMAC-SHA256
Future<List<int>> _derivePairingKey(List<int> sharedSecret) async {
  final hmac = Hmac.sha256();
  final secretKey = SecretKey(sharedSecret);
  final label = utf8.encode('avodah-pair-v1');
  final mac = await hmac.calculateMac(
    label,
    secretKey: secretKey,
  );
  return mac.bytes;
}

/// Generates a sync verification code using HMAC-SHA256
Future<String> _generateSyncVerifyCode(List<int> pairingKey) async {
  final hmac = Hmac.sha256();
  final secretKey = SecretKey(pairingKey);
  final label = utf8.encode('avodah-sync-v1');
  final mac = await hmac.calculateMac(
    label,
    secretKey: secretKey,
  );
  // Return base64-encoded HMAC tag
  return base64Encode(mac.bytes);
}

/// Verifies a sync code in constant time using constant-time comparison
bool _verifySyncCode(String expectedCode, String actualCode) {
  // Use constant-time comparison to prevent timing attacks
  if (expectedCode.length != actualCode.length) return false;

  int result = 0;
  for (int i = 0; i < expectedCode.length; i++) {
    result |= expectedCode.codeUnitAt(i) ^ actualCode.codeUnitAt(i);
  }
  return result == 0;
}

/// Generates a cryptographically secure 6-digit code
String generateSixDigitCode() {
  final random = Random.secure();
  // Generate a number between 0 and 999999, padded to 6 digits
  final value = random.nextInt(1000000);
  return value.toString().padLeft(6, '0');
}

/// Generates a new X25519 key pair for secure pairing
Future<KeyPair> generateKeyPair() async {
  final algorithm = X25519();
  final keyPair = await algorithm.newKeyPair();

  final publicKeyBytes = await keyPair.extractPublicKey();
  final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

  return KeyPair(
    publicKey: publicKeyBytes.bytes,
    privateKey: privateKeyBytes,
  );
}

/// Derives a shared secret from two key pairs using X25519 ECDH
Future<List<int>> deriveSharedSecret(
  KeyPair localKeyPair,
  List<int> remotePublicKey,
) async {
  final algorithm = X25519();

  // Create a key pair from the stored private key bytes
  final localKeyPairData = await algorithm.newKeyPairFromSeed(
    Uint8List.fromList(localKeyPair.privateKey),
  );

  // Create a SimplePublicKey from the remote public key
  final remotePubKey = SimplePublicKey(
    remotePublicKey,
    type: KeyPairType.x25519,
  );

  // Perform ECDH to derive shared secret
  final sharedSecret = await algorithm.sharedSecretKey(
    keyPair: localKeyPairData,
    remotePublicKey: remotePubKey,
  );

  return sharedSecret.extractBytes();
}

/// Derives the pairing key from a shared secret (used after ECDH)
Future<List<int>> derivePairingKey(List<int> sharedSecret) async {
  return _derivePairingKey(sharedSecret);
}

/// Generates a sync verification code from a pairing key
Future<String> generateSyncVerifyCode(List<int> pairingKey) async {
  return _generateSyncVerifyCode(pairingKey);
}

/// Verifies a sync code against an expected value
bool verifySyncCode(String expectedCode, String actualCode) {
  return _verifySyncCode(expectedCode, actualCode);
}