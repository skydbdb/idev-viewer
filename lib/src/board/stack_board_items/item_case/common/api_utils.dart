import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:idev_v1/src/repo/home_repo.dart';
import 'package:idev_v1/src/repo/app_streams.dart';

/// API 관련 공통 유틸리티 클래스
class ApiUtils {
  /// apiParameters 변경 시 script 자동 업데이트
  static void updateScriptFromApiParameters<T>(
    T item,
    String apiParameters,
    HomeRepo homeRepo,
    AppStreams appStreams,
    Function(T) copyWith,
    Function(T) updateStackItemState,
    Function(T) addOnTapState,
  ) {
    if (apiParameters.isEmpty) {
      return;
    }

    try {
      // apiParameters 파싱
      final scriptJson = generateScript(apiParameters);

      debugPrint('📝 속성창에서 자동 생성된 script: $scriptJson');

      // script 업데이트
      final updatedItem = copyWith(item);
      updateStackItemState(updatedItem);
      addOnTapState(updatedItem);

      debugPrint('✅ 속성창에서 script 자동 업데이트 완료');
    } catch (e) {
      debugPrint('❌ 속성창에서 script 자동 업데이트 실패: $e');
    }
  }

  /// 스크립트 설정 생성
  static String generateScript(String apiParameters) {
    final List<String> paramNames = apiParameters
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    final Map<String, Map<String, dynamic>> scriptConfig = {};
    for (final paramName in paramNames) {
      scriptConfig[paramName] = {
        'type': 'text',
        'hide': true,
        'default': '',
      };
      switch (paramName) {
        case 'latitude':
          scriptConfig[paramName]!['type'] = 'gps';
          break;
        case 'longitude':
          scriptConfig[paramName]!['type'] = 'gps';
          break;
        case 'check_in_time':
          scriptConfig[paramName]!['type'] = 'time_stamp';
          break;
        case 'check_out_time':
          scriptConfig[paramName]!['type'] = 'time_stamp';
          break;
      }
    }
    return jsonEncode(scriptConfig);
  }

  /// API ID 응답 스트림 구독
  static StreamSubscription subscribeApiIdResponse<T>(
    String boardId,
    String itemId,
    HomeRepo homeRepo,
    Function(T, String, List<String>) fetchResponseData,
  ) {
    return homeRepo.getApiIdResponseStream
        .skip(1)
        .where((v) => v != null)
        .listen((v) {
      debugPrint('ApiUtils: _subscribeApiIdResponse v = $v');
      if (v != null) {
        final controller = homeRepo.hierarchicalControllers[boardId];
        final item = controller?.getById(itemId);

        final String receivedApiId = v['if_id'];
        final List<String> targetWidgetIds = v.keys.contains('targetWidgetIds')
            ? v['targetWidgetIds']
            : v['targetWidgetIds'] ?? [];

        // 기설정된 API ID이거나 강제 주입 요청인지 검사
        // } && targetWidgetIds.contains(itemId)) {
        fetchResponseData(item as T, receivedApiId, targetWidgetIds);
      }
    });
  }

  /// API ID로부터 paramKey 목록을 추출해 ", "로 연결한 문자열 반환
  static String extractParamKeysByApiId(HomeRepo homeRepo, String apiId) {
    try {
      final api = homeRepo.apis[apiId];
      if (api == null) return '';

      if (api['parameters'] != null &&
          api['parameters'].toString().isNotEmpty) {
        final List<dynamic> parameters = jsonDecode(api['parameters']);
        final List<String> paramKeys = [];
        for (final param in parameters) {
          if (param is Map<String, dynamic> && param['paramKey'] != null) {
            paramKeys.add(param['paramKey'].toString());
          }
        }
        return paramKeys.join(', ');
      }
    } catch (e) {
      debugPrint('[ApiUtils] extractParamKeysByApiId 파싱 오류: $e');
    }
    return '';
  }

  /// API 응답 데이터 처리
  static void fetchResponseData<T>(
    T currentContent,
    String receivedApiId,
    HomeRepo homeRepo,
    String boardId,
    String itemId,
    Function(T) copyWith,
    Function(T) updateItem,
    Function(T) addOnTapState,
    Function(T, String) updateScriptFromApiParameters,
  ) {
    try {
      final api = homeRepo.apis[receivedApiId];

      // api['parameters']에서 paramKey만 추출하여 문자열로 반환
      String extractedParamKeys = '';
      if (api['parameters'] != null &&
          api['parameters'].toString().isNotEmpty) {
        try {
          final List<dynamic> parameters = jsonDecode(api['parameters']);
          List<String> paramKeys = [];
          for (var param in parameters) {
            if (param is Map<String, dynamic> && param['paramKey'] != null) {
              final paramKey = param['paramKey'].toString();
              paramKeys.add(paramKey);
            }
          }
          extractedParamKeys = paramKeys.join(', ');
        } catch (e) {
          debugPrint('[ApiUtils] 파라미터 파싱 오류: $e');
        }
      }

      final updatedItem = copyWith(currentContent);
      homeRepo.hierarchicalControllers[boardId]?.updateItem(updatedItem);
      homeRepo.addOnTapState(updatedItem);
      updateScriptFromApiParameters(updatedItem, extractedParamKeys);

      // 추출된 paramKey들을 디버그 출력
      debugPrint('[ApiUtils] 추출된 paramKey: $extractedParamKeys');
    } catch (e) {
      debugPrint('[ApiUtils] fetchResponseData error: $e');
    }
  }

  /// script 설정 파싱
  static Map<String, Map<String, dynamic>> parseScriptConfig(String? script) {
    if (script == null || script.isEmpty) {
      return {};
    }

    try {
      final Map<String, dynamic> config = jsonDecode(script);
      final Map<String, Map<String, dynamic>> result = {};

      for (final entry in config.entries) {
        result[entry.key] = Map<String, dynamic>.from(entry.value);
      }

      debugPrint('📋 스크립트 설정 파싱: $result');
      return result;
    } catch (e) {
      debugPrint('❌ 스크립트 설정 파싱 오류: $e');
      return {};
    }
  }

  /// apiParameters 파싱
  static List<Map<String, dynamic>> parseApiParameters(
      String? apiParametersJson) {
    if (apiParametersJson == null || apiParametersJson.isEmpty) {
      return [];
    }

    try {
      // JSON 형태인지 확인
      if (apiParametersJson.trim().startsWith('[')) {
        // JSON 파라미터 파싱
        final List<dynamic> parameters = jsonDecode(apiParametersJson);
        return parameters
            .map((param) => Map<String, dynamic>.from(param))
            .toList();
      } else {
        // 쉼표로 구분된 문자열 파싱
        final List<String> paramNames = apiParametersJson
            .split(',')
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty)
            .toList();

        return paramNames.map((paramName) {
          return {
            'paramKey': paramName,
            'isRequired': 'true',
            'type': 'string',
            'description': '',
            'in': 'body'
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('API 파라미터 파싱 오류: $e');
      return [];
    }
  }

  /// 스크립트 설정에 따른 값 할당
  static String getValueByScript(
    String paramKey,
    Map<String, dynamic> config,
    Map<String, dynamic>? locationData,
  ) {
    final valueType = config['type']?.toString() ?? 'text';

    switch (valueType) {
      case 'gps':
        // GPS 관련 파라미터 처리
        if (locationData != null) {
          if (paramKey == 'latitude') {
            return locationData['latitude']?.toString() ?? '37.5665';
          } else if (paramKey == 'longitude') {
            return locationData['longitude']?.toString() ?? '126.9780';
          }
          return 'gps';
        }
        return 'gps';
      case 'time_stamp':
        // 시간 관련 파라미터 처리
        if (paramKey.contains('time') || paramKey.contains('Time')) {
          return DateTime.now().toIso8601String();
        }
        return DateTime.now().toIso8601String();
      case 'text':
        return config['default']?.toString() ?? '';
      case 'number':
        return config['default']?.toString() ?? '0';
      default:
        // 파라미터 이름에 따른 자동 값 할당
        if (paramKey == 'latitude' && locationData != null) {
          return locationData['latitude']?.toString() ?? '37.5665';
        } else if (paramKey == 'longitude' && locationData != null) {
          return locationData['longitude']?.toString() ?? '126.9780';
        } else if (paramKey.contains('time') || paramKey.contains('Time')) {
          return DateTime.now().toIso8601String();
        } else if (paramKey == 'user_id') {
          return '1';
        } else if (paramKey.contains('method')) {
          return 'gps';
        }
        return config['default']?.toString() ?? '';
    }
  }

  /// 파라미터 타입 변환 및 정리
  static Map<String, dynamic> convertParameters(
      Map<String, dynamic> parameters) {
    final convertedParams = <String, dynamic>{};

    for (final entry in parameters.entries) {
      final key = entry.key;
      final value = entry.value;

      switch (key) {
        case 'user_id':
          // 문자열을 숫자로 변환
          convertedParams[key] = int.tryParse(value.toString()) ?? 1;
          break;
        case 'check_in_time':
        case 'check_out_time':
          // ISO8601 형식을 MySQL DATETIME 형식으로 변환
          try {
            final dateTime = DateTime.parse(value.toString());
            convertedParams[key] = dateTime
                .toIso8601String()
                .replaceAll('T', ' ')
                .substring(0, 19);
          } catch (e) {
            convertedParams[key] = value;
          }
          break;
        case 'latitude':
        case 'longitude':
          // 문자열을 double로 변환
          convertedParams[key] = double.tryParse(value.toString()) ?? 0.0;
          break;
        case 'check_in_method':
        case 'check_out_method':
          // 기본값 설정
          convertedParams[key] = value.toString().isNotEmpty ? value : 'gps';
          break;
        default:
          convertedParams[key] = value;
      }
    }

    debugPrint('🔄 파라미터 변환: $parameters -> $convertedParams');
    return convertedParams;
  }

  /// 파라미터와 함께 API 직접 실행
  static Future<void> executeApiWithParameters(
    String apiId,
    HomeRepo homeRepo,
    Map<String, dynamic> parameters,
    Function(String) showErrorSnackBar,
    Function(String) showSuccessSnackBar,
  ) async {
    try {
      debugPrint('API 직접 실행: $apiId, 파라미터: $parameters');

      // API 정보 조회
      final api = homeRepo.apis[apiId];
      if (api == null) {
        showErrorSnackBar('API 정보를 찾을 수 없습니다: $apiId');
        return;
      }

      // API 파라미터를 ApiPopupDialog 형식으로 변환
      final List<Map<String, dynamic>> apiParams =
          parameters.entries.map((entry) {
        return {
          'paramKey': entry.key,
          'isRequired': 'true',
          'type': 'string',
          'description': entry.value.toString(),
          'in': 'body'
        };
      }).toList();

      // API 실행을 위한 파라미터 구성
      final Map<String, dynamic> requestParams = {
        'targetWidgetIds': [],
        'apiNm': api['apiNm'] ?? api['api_nm'],
        'request': api['request'] ?? '{}',
        'parameters': jsonEncode(apiParams),
        // 파라미터 타입 변환 및 정리
        ...convertParameters(parameters),
      };

      debugPrint('API 실행 파라미터: $requestParams');

      // API 요청 실행
      homeRepo.addApiRequest(apiId, requestParams);

      showSuccessSnackBar('API 실행이 완료되었습니다.');
    } catch (e) {
      debugPrint('API 실행 오류: $e');
      showErrorSnackBar('API 실행 중 오류가 발생했습니다: $e');
    }
  }

  /// 기본값 할당 (하위 호환성)
  static String getDefaultValue(
      String key, Map<String, dynamic>? locationData) {
    switch (key) {
      case 'latitude':
        return locationData?['latitude']?.toString() ?? '37.5665';
      case 'longitude':
        return locationData?['longitude']?.toString() ?? '126.9780';
      case 'check_in_time':
      case 'check_out_time':
        return DateTime.now().toIso8601String();
      case 'user_id':
        return '1';
      case 'check_in_method':
      case 'check_out_method':
        return 'gps';
      default:
        return '';
    }
  }
}
