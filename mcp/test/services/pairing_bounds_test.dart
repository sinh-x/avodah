import 'package:avodah_mcp/services/pairing_service.dart';
import 'package:avodah_mcp/storage/database_opener.dart';
import 'package:test/test.dart';

void main() {
  test('32 concurrent challenges bounded; expiry frees capacity', () async {
    final db = openMemoryDatabase();
    var now = DateTime.now();
    final pairing = PairingService(db: db, now: () => now, deliverCode: (_) {});
    try {
      await Future.wait(
          [for (var i = 0; i < 32; i++) pairing.startPairing('fixture-$i')]);
      await expectLater(pairing.startPairing('overflow'), throwsStateError);
      now = now.add(const Duration(seconds: 300));
      expect((await pairing.startPairing('after-expiry'))['expiresIn'], 300);
    } finally {
      await db.close();
    }
  });
  test('per-source/global budgets are bounded and reset after one minute',
      () async {
    final db = openMemoryDatabase();
    var now = DateTime.now();
    final pairing = PairingService(db: db, now: () => now, deliverCode: (_) {});
    try {
      for (var source = 0; source < 10; source++) {
        for (var n = 0; n < 10; n++) {
          expect(pairing.admitStart('source-$source'), true);
        }
        expect(pairing.admitStart('source-$source'), false);
      }
      expect(pairing.admitStart('new-source'), false);
      now = now.add(const Duration(minutes: 1));
      expect(pairing.admitStart('source-0'), true);
    } finally {
      await db.close();
    }
  });
}
