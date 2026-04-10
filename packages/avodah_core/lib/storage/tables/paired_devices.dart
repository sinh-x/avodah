import 'package:drift/drift.dart';

/// Paired devices table - stores paired device public keys for secure sync
/// Used during the pairing handshake to establish trusted connections
class PairedDevices extends Table {
  // Core identification
  TextColumn get id => text()();

  // Public key for this device (used for key exchange)
  BlobColumn get publicKey => blob()();

  // Optional encrypted private key reference (for key recovery)
  BlobColumn get privateKey => blob().nullable()();

  // Timestamps
  IntColumn get created => integer()(); // Unix ms
  IntColumn get lastSeen => integer().nullable()(); // Unix ms

  @override
  Set<Column> get primaryKey => {id};
}