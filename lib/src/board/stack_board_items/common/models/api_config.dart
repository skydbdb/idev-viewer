import 'dart:convert';

class ApiConfig {
  final String apiId;
  final String? field;
  final String? type;
  final String? fieldNm;
  final int? width;
  final String? align;
  final String? format;
  final bool? enabled;

  ApiConfig({
    required this.apiId,
    this.field,
    this.type,
    this.fieldNm,
    this.width,
    this.align,
    this.format,
    this.enabled,
  });

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    bool? parseBool(dynamic v, {bool? defaultValue}) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return defaultValue;
    }

    return ApiConfig(
      apiId: json['apiId'] as String,
      field: json['field'] as String?,
      type: json['type'] as String?,
      fieldNm: json['fieldNm'] as String?,
      width: json['width'] is int
          ? json['width'] as int
          : int.tryParse(json['width']?.toString() ?? ''),
      align: json['align'] as String?,
      format: json['format'] as String?,
      enabled: parseBool(json['enabled'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiId': apiId,
      if (field != null) 'field': field,
      if (type != null) 'type': type,
      if (fieldNm != null) 'fieldNm': fieldNm,
      if (width != null) 'width': width.toString(),
      if (align != null) 'align': align,
      if (format != null) 'format': format,
      if (enabled != null) 'enabled': enabled,
    };
  }
}

// 유틸리티 함수 (ApiConfig 리스트와 JSON 문자열 간 변환)
List<ApiConfig> apiConfigsFromJsonString(String? jsonString) {
  if (jsonString == null || jsonString.isEmpty || jsonString == 'null') {
    return [];
  }
  try {
    final List<dynamic> decodedList = jsonDecode(jsonString);
    return decodedList
        .map((item) => ApiConfig.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print(
        'Error parsing ApiConfig list from JSON string: $jsonString, Error: $e');
    return [];
  }
}

String apiConfigsToJsonString(List<ApiConfig>? apiConfigs) {
  if (apiConfigs == null || apiConfigs.isEmpty) {
    return '[]';
  }
  try {
    return jsonEncode(apiConfigs.map((config) => config.toJson()).toList());
  } catch (e) {
    print('Error encoding ApiConfig list to JSON string: $e');
    return '[]';
  }
}
