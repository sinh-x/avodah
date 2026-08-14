import 'package:flutter_test/flutter_test.dart';
import 'package:avodah_viewer/models/session_record.dart';

void main() {
  group('SessionRecord.fromJson key normalization (Mn3/AC15)', () {
    test('reads camelCase deploymentId (canonical key)', () {
      final r = SessionRecord.fromJson({
        'id': 's1',
        'deploymentId': 'd-abcdef',
        'status': 'running',
      });
      expect(r.id, 's1');
      expect(r.deploymentId, 'd-abcdef');
      expect(r.status, 'running');
    });

    test('falls back to snake_case deployment_id', () {
      final r = SessionRecord.fromJson({
        'id': 's1',
        'deployment_id': 'd-snake123',
        'status': 'running',
      });
      expect(r.deploymentId, 'd-snake123');
    });

    test('prefers camelCase over snake_case when both present', () {
      final r = SessionRecord.fromJson({
        'id': 's1',
        'deploymentId': 'd-camel',
        'deployment_id': 'd-snake',
        'status': 'running',
      });
      expect(r.deploymentId, 'd-camel');
    });

    test('returns null when neither key present', () {
      final r = SessionRecord.fromJson({
        'id': 's1',
        'status': 'running',
      });
      expect(r.deploymentId, isNull);
    });

    test('returns null when value is empty string', () {
      final r = SessionRecord.fromJson({
        'id': 's1',
        'deploymentId': '',
        'status': 'running',
      });
      expect(r.deploymentId, isNull);
    });

    test('returns null when value is not a string', () {
      final r = SessionRecord.fromJson({
        'id': 's1',
        'deploymentId': 123,
        'status': 'running',
      });
      expect(r.deploymentId, isNull);
    });

    test('parses model field when present', () {
      final r = SessionRecord.fromJson({
        'id': 's1',
        'deploymentId': 'd-abc',
        'model': 'ollama-cloud/glm-5',
        'status': 'running',
      });
      expect(r.model, 'ollama-cloud/glm-5');
    });
  });
}