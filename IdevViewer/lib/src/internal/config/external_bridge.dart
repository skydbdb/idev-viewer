import 'dart:async';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';

/// 외부(iframe parent 등)에서 전달되는 apiKey와 템플릿 스크립트를
/// 앱 내부로 브릿지하는 최소 인터페이스.
class ExternalBridge {
  static String? apiKey;
  static HomeRepo? _homeRepo;

  static final StreamController<Map<String, dynamic>?> _templateController =
      StreamController<Map<String, dynamic>?>.broadcast();

  static Stream<Map<String, dynamic>?> get templateStream =>
      _templateController.stream;

  static void pushTemplate(Map<String, dynamic>? template) {
    _templateController.add(template);
  }

  // README 가이드: 직접 인스턴스 관리 방식
  static void setHomeRepo(HomeRepo homeRepo) {
    _homeRepo = homeRepo;
  }

  static HomeRepo? get homeRepo => _homeRepo;
}
