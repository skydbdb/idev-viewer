import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// GPS 위치 정보 획득 서비스
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// 현재 위치 정보 획득
  Future<Map<String, dynamic>> getCurrentLocation({
    int timeoutSeconds = 15,
    double accuracyThreshold = 100.0,
  }) async {
    try {
      debugPrint('📍 GPS 위치 정보 획득 시작...');

      // 웹 환경에서는 기본값 반환
      if (kIsWeb) {
        debugPrint('🌐 웹 환경 감지 - 기본값 사용');
        return _getDefaultLocation();
      }

      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('📍 위치 서비스 활성화 상태: $serviceEnabled');

      if (!serviceEnabled) {
        throw LocationException('위치 서비스가 비활성화되어 있습니다. 설정에서 위치 서비스를 활성화해주세요.');
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 현재 위치 권한: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('📍 위치 권한 요청 중...');
        permission = await Geolocator.requestPermission();
        debugPrint('📍 권한 요청 결과: $permission');

        if (permission == LocationPermission.denied) {
          throw LocationException('위치 권한이 거부되었습니다. 앱 설정에서 위치 권한을 허용해주세요.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationException('위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 위치 권한을 허용해주세요.');
      }

      debugPrint('📍 위치 정보 획득 중... (타임아웃: $timeoutSeconds초)');

      // 현재 위치 획득
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: timeoutSeconds),
      );

      debugPrint(
          '📍 위치 정보 획득 성공: lat=${position.latitude}, lng=${position.longitude}, accuracy=${position.accuracy}m');

      // 위치 정확도 검증 (경고만 표시, 오류로 처리하지 않음)
      if (position.accuracy > accuracyThreshold) {
        debugPrint(
            '⚠️ 위치 정확도가 낮습니다: ${position.accuracy.toStringAsFixed(1)}m (허용: ${accuracyThreshold}m)');
        // 정확도가 낮아도 계속 진행
      }

      // 한국 영역 확인 (대략적인 범위) - 경고만 표시
      if (position.latitude < 33.0 ||
          position.latitude > 39.0 ||
          position.longitude < 124.0 ||
          position.longitude > 132.0) {
        debugPrint(
            '⚠️ 한국 영역 밖의 위치입니다: lat=${position.latitude}, lng=${position.longitude}');
        // 한국 영역 밖이어도 계속 진행
      }

      final result = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
        'timestamp': position.timestamp.millisecondsSinceEpoch,
        'timestampFormatted': DateTime.now().toIso8601String(),
      };

      debugPrint('📍 GPS 위치 정보 반환: $result');
      return result;
    } catch (e) {
      debugPrint('❌ GPS 위치 정보 획득 실패: $e');

      // MissingPluginException 처리 (웹 환경 또는 플러그인 미등록)
      if (e.toString().contains('MissingPluginException')) {
        debugPrint('🔌 플러그인 미등록 감지 - 기본값 사용');
        return _getDefaultLocation();
      }

      if (e is LocationException) {
        rethrow;
      }

      // geolocator 패키지의 구체적인 오류 처리
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw LocationException('위치 권한이 거부되었습니다. 앱 설정에서 위치 권한을 허용해주세요.');
      } else if (e.toString().contains('POSITION_UNAVAILABLE')) {
        throw LocationException('위치 정보를 사용할 수 없습니다. GPS 신호를 확인해주세요.');
      } else if (e.toString().contains('TIMEOUT')) {
        throw LocationException('위치 정보 요청 시간이 초과되었습니다. 다시 시도해주세요.');
      } else {
        debugPrint('🔌 기타 오류 감지 - 기본값 사용');
        return _getDefaultLocation();
      }
    }
  }

  /// 기본 위치 정보 반환 (서울시청)
  Map<String, dynamic> _getDefaultLocation() {
    final defaultLocation = {
      'latitude': 37.5665,
      'longitude': 126.9780,
      'accuracy': 100.0,
      'altitude': 0.0,
      'heading': 0.0,
      'speed': 0.0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'timestampFormatted': DateTime.now().toIso8601String(),
    };
    debugPrint('📍 기본 위치 정보 반환: $defaultLocation');
    return defaultLocation;
  }

  /// 위치 권한 상태 확인
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// 위치 서비스 활성화 상태 확인
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}

/// 위치 관련 예외 클래스
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}

/// 위치 정보 획득 위젯
class LocationAcquisitionWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onLocationAcquired;
  final Function(String) onError;
  final Widget child;

  const LocationAcquisitionWidget({
    super.key,
    required this.onLocationAcquired,
    required this.onError,
    required this.child,
  });

  @override
  State<LocationAcquisitionWidget> createState() =>
      _LocationAcquisitionWidgetState();
}

class _LocationAcquisitionWidgetState extends State<LocationAcquisitionWidget> {
  bool _isAcquiring = false;
  String? _statusMessage;

  Future<void> _acquireLocation() async {
    if (_isAcquiring) return;

    setState(() {
      _isAcquiring = true;
      _statusMessage = '위치 정보를 획득하고 있습니다...';
    });

    try {
      final location = await LocationService().getCurrentLocation();
      widget.onLocationAcquired(location);

      setState(() {
        _isAcquiring = false;
        _statusMessage = '위치 정보 획득 완료';
      });
    } catch (e) {
      setState(() {
        _isAcquiring = false;
        _statusMessage = '위치 정보 획득 실패';
      });
      widget.onError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_statusMessage != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: _isAcquiring ? Colors.blue : Colors.green,
                fontSize: 12,
              ),
            ),
          ),
        GestureDetector(
          onTap: _acquireLocation,
          child: Opacity(
            opacity: _isAcquiring ? 0.6 : 1.0,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
