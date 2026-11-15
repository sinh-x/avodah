import 'dart:async';
import 'dart:io';
import 'package:avodah_mcp/services/sync_request_policy.dart';
import 'package:test/test.dart';

void main() {
  test('streaming limit rejects chunked overrun and cancels source', () async {
    var cancelled = false;
    final source =
        StreamController<List<int>>(onCancel: () => cancelled = true);
    final future = readBoundedBytes(source.stream, 8);
    source.add(List.filled(9, 1));
    await expectLater(future, throwsA(isA<HttpException>()));
    expect(cancelled, true);
    await source.close();
  });
  test('deadline is total, not extended by dribbling chunks', () async {
    var cancelled = false;
    final source =
        StreamController<List<int>>(onCancel: () => cancelled = true);
    final timer = Timer.periodic(
        const Duration(milliseconds: 10), (_) => source.add([1]));
    final watch = Stopwatch()..start();
    try {
      await expectLater(
          readBoundedBytes(source.stream, 1000,
              deadline: const Duration(milliseconds: 80)),
          throwsA(isA<TimeoutException>()));
      expect(watch.elapsedMilliseconds, lessThan(500));
      expect(cancelled, true);
    } finally {
      timer.cancel();
      await source.close();
    }
  });
}
