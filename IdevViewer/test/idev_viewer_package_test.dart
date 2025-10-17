import 'package:flutter_test/flutter_test.dart';
import 'package:idev_viewer/idev_viewer.dart';

void main() {
  group('IDevConfig', () {
    test('creates config with all parameters', () {
      final config = IDevConfig(
        apiKey: 'test-key',
        template: {'type': 'container'},
        templateName: 'test-template',
        viewerUrl: 'https://example.com',
      );

      expect(config.apiKey, 'test-key');
      expect(config.template, {'type': 'container'});
      expect(config.templateName, 'test-template');
      expect(config.viewerUrl, 'https://example.com');
    });

    test('converts to JSON correctly', () {
      final config = IDevConfig(
        apiKey: 'test-key',
        template: {'type': 'container'},
      );

      final json = config.toJson();
      expect(json['apiKey'], 'test-key');
      expect(json['template'], {'type': 'container'});
    });

    test('creates from JSON correctly', () {
      final json = {
        'apiKey': 'test-key',
        'template': {'type': 'container'},
        'templateName': 'test-template',
      };

      final config = IDevConfig.fromJson(json);
      expect(config.apiKey, 'test-key');
      expect(config.template, {'type': 'container'});
      expect(config.templateName, 'test-template');
    });
  });

  group('IDevEvent', () {
    test('creates event with required parameters', () {
      final event = IDevEvent(
        type: 'test-event',
        data: {'key': 'value'},
      );

      expect(event.type, 'test-event');
      expect(event.data, {'key': 'value'});
      expect(event.timestamp, isA<DateTime>());
    });

    test('converts to JSON correctly', () {
      final event = IDevEvent(
        type: 'test-event',
        data: {'key': 'value'},
      );

      final json = event.toJson();
      expect(json['type'], 'test-event');
      expect(json['data'], {'key': 'value'});
      expect(json['timestamp'], isA<int>());
    });

    test('creates from JSON correctly', () {
      final json = {
        'type': 'test-event',
        'data': {'key': 'value'},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final event = IDevEvent.fromJson(json);
      expect(event.type, 'test-event');
      expect(event.data, {'key': 'value'});
      expect(event.timestamp, isA<DateTime>());
    });

    test('toString returns formatted string', () {
      final event = IDevEvent(
        type: 'test-event',
        data: {'key': 'value'},
      );

      expect(event.toString(), contains('test-event'));
      expect(event.toString(), contains('{key: value}'));
    });
  });
}
