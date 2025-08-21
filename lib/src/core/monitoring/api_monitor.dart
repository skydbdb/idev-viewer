import 'dart:async';
import 'dart:developer' as developer;

class ApiMonitor {
  static final ApiMonitor _instance = ApiMonitor._internal();
  factory ApiMonitor() => _instance;
  ApiMonitor._internal();

  // API 호출 통계
  final Map<String, List<ApiCallRecord>> _apiCallHistory = {};
  final Map<String, int> _errorCounts = {};
  final Map<String, int> _successCounts = {};

  // 성능 임계값
  static const Duration _slowResponseThreshold = Duration(seconds: 3);
  static const Duration _verySlowResponseThreshold = Duration(seconds: 10);

  /// API 호출 시작 기록
  void startApiCall(String apiId, String url) {
    final record = ApiCallRecord(
      apiId: apiId,
      url: url,
      startTime: DateTime.now(),
    );

    _apiCallHistory.putIfAbsent(apiId, () => []).add(record);

    developer.log(
      '🚀 API 호출 시작: $apiId',
      name: 'ApiMonitor',
      error: 'URL: $url',
    );
  }

  /// API 호출 완료 기록
  void endApiCall(String apiId, bool isSuccess,
      {String? errorMessage, int? statusCode}) {
    final history = _apiCallHistory[apiId];
    if (history == null || history.isEmpty) return;

    final record = history.last;
    record.endTime = DateTime.now();
    record.isSuccess = isSuccess;
    record.errorMessage = errorMessage;
    record.statusCode = statusCode;

    // 통계 업데이트
    if (isSuccess) {
      _successCounts[apiId] = (_successCounts[apiId] ?? 0) + 1;
    } else {
      _errorCounts[apiId] = (_errorCounts[apiId] ?? 0) + 1;
    }

    // 성능 분석
    _analyzePerformance(record);

    developer.log(
      '✅ API 호출 완료: $apiId (${record.duration?.inMilliseconds}ms)',
      name: 'ApiMonitor',
      error: isSuccess ? null : '오류: $errorMessage',
    );
  }

  /// 성능 분석
  void _analyzePerformance(ApiCallRecord record) {
    final duration = record.duration;
    if (duration == null) return;

    if (duration > _verySlowResponseThreshold) {
      developer.log(
        '🐌 매우 느린 응답 감지: ${record.apiId} (${duration.inMilliseconds}ms)',
        name: 'ApiMonitor',
        level: 900, // ERROR level
      );
    } else if (duration > _slowResponseThreshold) {
      developer.log(
        '⚠️ 느린 응답 감지: ${record.apiId} (${duration.inMilliseconds}ms)',
        name: 'ApiMonitor',
        level: 800, // WARNING level
      );
    }
  }

  /// API 통계 가져오기
  ApiStats getApiStats(String apiId) {
    final history = _apiCallHistory[apiId] ?? [];
    final errorCount = _errorCounts[apiId] ?? 0;
    final successCount = _successCounts[apiId] ?? 0;
    final totalCount = history.length;

    if (totalCount == 0) {
      return ApiStats(
        apiId: apiId,
        totalCalls: 0,
        successRate: 0.0,
        averageResponseTime: Duration.zero,
        errorRate: 0.0,
      );
    }

    final successfulCalls = history
        .where((r) => r.isSuccess == true && r.duration != null)
        .toList();
    final averageResponseTime = successfulCalls.isEmpty
        ? Duration.zero
        : Duration(
            milliseconds: successfulCalls
                    .map((r) => r.duration?.inMilliseconds ?? 0)
                    .reduce((a, b) => a + b) ~/
                successfulCalls.length,
          );

    return ApiStats(
      apiId: apiId,
      totalCalls: totalCount,
      successRate: totalCount > 0 ? (successCount / totalCount) * 100 : 0.0,
      averageResponseTime: averageResponseTime,
      errorRate: totalCount > 0 ? (errorCount / totalCount) * 100 : 0.0,
    );
  }

  /// 전체 API 통계 가져오기
  List<ApiStats> getAllApiStats() {
    final allApiIds = _apiCallHistory.keys.toSet();
    return allApiIds.map((apiId) => getApiStats(apiId)).toList();
  }

  /// 성능 문제가 있는 API 목록 가져오기
  List<String> getSlowApis() {
    final slowApis = <String>[];

    for (final apiId in _apiCallHistory.keys) {
      final stats = getApiStats(apiId);
      if (stats.averageResponseTime > _slowResponseThreshold) {
        slowApis.add(apiId);
      }
    }

    return slowApis;
  }

  /// 오류율이 높은 API 목록 가져오기
  List<String> getHighErrorRateApis({double threshold = 10.0}) {
    final highErrorApis = <String>[];

    for (final apiId in _apiCallHistory.keys) {
      final stats = getApiStats(apiId);
      if (stats.errorRate > threshold) {
        highErrorApis.add(apiId);
      }
    }

    return highErrorApis;
  }

  /// 로그 정리 (메모리 관리)
  void cleanupOldRecords({int maxRecordsPerApi = 100}) {
    for (final apiId in _apiCallHistory.keys) {
      final history = _apiCallHistory[apiId]!;
      if (history.length > maxRecordsPerApi) {
        history.removeRange(0, history.length - maxRecordsPerApi);
      }
    }
  }
}

/// API 호출 기록
class ApiCallRecord {
  final String apiId;
  final String url;
  final DateTime startTime;
  DateTime? endTime;
  bool? isSuccess;
  String? errorMessage;
  int? statusCode;

  ApiCallRecord({
    required this.apiId,
    required this.url,
    required this.startTime,
  });

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }
}

/// API 통계
class ApiStats {
  final String apiId;
  final int totalCalls;
  final double successRate;
  final Duration averageResponseTime;
  final double errorRate;

  ApiStats({
    required this.apiId,
    required this.totalCalls,
    required this.successRate,
    required this.averageResponseTime,
    required this.errorRate,
  });

  @override
  String toString() {
    return 'ApiStats($apiId): 총 호출=$totalCalls, 성공률=${successRate.toStringAsFixed(1)}%, '
        '평균 응답시간=${averageResponseTime.inMilliseconds}ms, 오류율=${errorRate.toStringAsFixed(1)}%';
  }
}
