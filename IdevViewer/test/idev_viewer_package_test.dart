import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idev_viewer/idev_viewer.dart';

void main() {
  group('IdevViewer Tests', () {
    testWidgets('IdevViewer widget creation test', (WidgetTester tester) async {
      // 템플릿 생성
      final template = Template(
        script: '{"widgets":[],"layout":{},"config":{}}',
        templateId: 'test_template',
        templateNm: 'Test Template',
        commitInfo: 'v1.0.0',
      );

      // 뷰어 위젯 생성
      final viewer = IdevViewer(
        template: template,
        config: const Config(),
        width: 300,
        height: 200,
      );

      // 위젯 빌드 및 테스트
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: viewer,
          ),
        ),
      );

      // 위젯이 정상적으로 생성되었는지 확인
      expect(find.byType(IdevViewer), findsOneWidget);
    });

    testWidgets('Template model test', (WidgetTester tester) async {
      final template = Template(
        script: '{"test": "data"}',
        templateId: 'test_id',
        templateNm: 'Test Name',
        commitInfo: 'v1.0.0',
      );

      // JSON 변환 테스트
      final json = template.toJson();
      expect(json['script'], equals('{"test": "data"}'));
      expect(json['templateId'], equals('test_id'));
      expect(json['templateNm'], equals('Test Name'));
      expect(json['commitInfo'], equals('v1.0.0'));

      // JSON에서 복원 테스트
      final restoredTemplate = Template.fromJson(json);
      expect(restoredTemplate.script, equals(template.script));
      expect(restoredTemplate.templateId, equals(template.templateId));
      expect(restoredTemplate.templateNm, equals(template.templateNm));
      expect(restoredTemplate.commitInfo, equals(template.commitInfo));
    });

    testWidgets('Config model test', (WidgetTester tester) async {
      final config = Config(
        theme: 'light',
        locale: 'en',
        debug: true,
        platform: 'web',
      );

      // JSON 변환 테스트
      final json = config.toJson();
      expect(json['theme'], equals('light'));
      expect(json['locale'], equals('en'));
      expect(json['debug'], equals(true));
      expect(json['platform'], equals('web'));

      // JSON에서 복원 테스트
      final restoredConfig = Config.fromJson(json);
      expect(restoredConfig.theme, equals(config.theme));
      expect(restoredConfig.locale, equals(config.locale));
      expect(restoredConfig.debug, equals(config.debug));
      expect(restoredConfig.platform, equals(config.platform));
    });

    testWidgets('ViewerOptions model test', (WidgetTester tester) async {
      final template = Template(
        script: '{"test": "data"}',
        templateId: 'test_id',
        templateNm: 'Test Name',
        commitInfo: 'v1.0.0',
      );

      final config = Config(theme: 'dark', locale: 'ko');

      final options = ViewerOptions(
        width: 400,
        height: 300,
        template: template,
        config: config,
      );

      // JSON 변환 테스트
      final json = options.toJson();
      expect(json['width'], equals(400));
      expect(json['height'], equals(300));
      expect(json['template'], isNotNull);
      expect(json['config'], isNotNull);
    });
  });
}
