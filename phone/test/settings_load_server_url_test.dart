import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avodah_viewer/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsScreen.loadServerUrl', () {
    test('returns default URL on first launch', () async {
      final url = await SettingsScreen.loadServerUrl();
      expect(url, kDefaultServerUrl);
    });

    test('persists default URL to prefs on first launch', () async {
      await SettingsScreen.loadServerUrl();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kServerUrlKey), kDefaultServerUrl);
    });

    test('returns stored URL when set', () async {
      SharedPreferences.setMockInitialValues({
        kServerUrlKey: 'https://example.tail10c2c6.ts.net/avodah',
      });
      final url = await SettingsScreen.loadServerUrl();
      expect(url, 'https://example.tail10c2c6.ts.net/avodah');
    });

    test('migrates legacy ws:// URL to http://', () async {
      SharedPreferences.setMockInitialValues({
        kServerUrlKey: 'ws://100.64.0.1:9847',
      });
      final url = await SettingsScreen.loadServerUrl();
      expect(url, 'http://100.64.0.1:9847');
    });

    test('migrates legacy wss:// URL to http://', () async {
      // wss → http (the regex strips both wss and ws to http)
      SharedPreferences.setMockInitialValues({
        kServerUrlKey: 'wss://drgnfly.tail10c2c6.ts.net:9847',
      });
      final url = await SettingsScreen.loadServerUrl();
      expect(url, 'http://drgnfly.tail10c2c6.ts.net:9847');
    });

    test('strips trailing slashes', () async {
      SharedPreferences.setMockInitialValues({
        kServerUrlKey: 'https://drgnfly.tail10c2c6.ts.net/avodah///',
      });
      final url = await SettingsScreen.loadServerUrl();
      expect(url, 'https://drgnfly.tail10c2c6.ts.net/avodah');
    });

    test('persists migrated URL back to prefs', () async {
      SharedPreferences.setMockInitialValues({
        kServerUrlKey: 'ws://100.64.0.1:9847/',
      });
      await SettingsScreen.loadServerUrl();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kServerUrlKey), 'http://100.64.0.1:9847');
    });
  });
}
