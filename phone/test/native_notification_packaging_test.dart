import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'main Android startup selects native alerts, not a trial-only provider',
    () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('if (NativeNotificationClient.supported)'));
      expect(main, contains('NativeNotificationClient('));
      expect(main, isNot(contains('NotificationPushClient')));
      // Trial isolation still changes only the fresh-install default server.
      expect(
        main,
        contains("fallbackUrl: nativeTrial ? 'https://127.0.0.1:9847' : null"),
      );
    },
  );

  test('phone packages and Android integration contain no Firebase setup', () {
    final dependencies = File('pubspec.yaml').readAsStringSync();
    expect(dependencies, isNot(contains('firebase_core:')));
    expect(dependencies, isNot(contains('firebase_messaging:')));
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest.toLowerCase(), isNot(contains('firebase')));
    expect(manifest, contains('android:name=".NotificationListenerService"'));
    for (final path in [
      'android/app/build.gradle.kts',
      'android/settings.gradle.kts',
    ]) {
      expect(File(path).readAsStringSync(), isNot(contains('google-services')));
    }
    expect(
      File('lib/services/notification_push_client.dart').existsSync(),
      false,
    );
  });
}
