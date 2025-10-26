import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkUtils {
  /// 인터넷 연결 상태 확인
  static Future<bool> isInternetConnected() async {
    try {
      // 웹 환경에서는 항상 연결된 것으로 가정
      if (kIsWeb) {
        return true;
      }

      // 네이티브 환경에서만 실제 연결 테스트
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('NetworkUtils: 인터넷 연결 확인 실패: $e');
      // 오류 발생 시 연결된 것으로 가정 (API 호출이 차단되지 않도록)
      return true;
    }
  }

  /// 네트워크 타입 확인
  static Future<String> getNetworkType() async {
    try {
      final isConnected = await isInternetConnected();
      return isConnected ? 'Connected' : 'Disconnected';
    } catch (e) {
      print('NetworkUtils: 네트워크 타입 확인 실패: $e');
      return 'Connected'; // 기본값을 연결된 것으로 설정
    }
  }

  /// 서버 연결 테스트
  static Future<bool> testServerConnection(String host, int port) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 항상 성공으로 가정
        return true;
      }

      final socket = await Socket.connect(host, port,
          timeout: const Duration(seconds: 10));
      await socket.close();
      return true;
    } catch (e) {
      print('NetworkUtils: 서버 연결 테스트 실패 ($host:$port): $e');
      return false;
    }
  }

  /// 연결 품질 확인 (ping 테스트)
  static Future<Duration?> pingServer(String host) async {
    try {
      if (kIsWeb) {
        // 웹 환경에서는 기본값 반환
        return const Duration(milliseconds: 100);
      }

      final stopwatch = Stopwatch()..start();
      final socket =
          await Socket.connect(host, 80, timeout: const Duration(seconds: 5));
      await socket.close();
      stopwatch.stop();
      return stopwatch.elapsed;
    } catch (e) {
      print('NetworkUtils: Ping 테스트 실패 ($host): $e');
      return null;
    }
  }
}
