// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'behavior.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BehaviorImpl _$$BehaviorImplFromJson(Map<String, dynamic> json) =>
    _$BehaviorImpl(
      type: $enumDecode(_$TypeEnumMap, json['type']),
      method: $enumDecodeNullable(_$MethodEnumMap, json['method']),
      uri: json['uri'] as String?,
      requiredParameter: (json['requiredParameter'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      requiredTarget: json['requiredTarget'] as String?,
      permission: (json['permission'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      defaultParameter: json['defaultParameter'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$BehaviorImplToJson(_$BehaviorImpl instance) {
  final val = <String, dynamic>{
    'type': _$TypeEnumMap[instance.type]!,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('method', _$MethodEnumMap[instance.method]);
  writeNotNull('uri', instance.uri);
  writeNotNull('requiredParameter', instance.requiredParameter);
  writeNotNull('requiredTarget', instance.requiredTarget);
  writeNotNull('permission', instance.permission);
  writeNotNull('defaultParameter', instance.defaultParameter);
  return val;
}

const _$TypeEnumMap = {
  Type.self: 'self',
  Type.autoSearch: 'auto-search',
  Type.search: 'search',
  Type.update: 'update',
};

const _$MethodEnumMap = {
  Method.post: 'post',
  Method.put: 'put',
  Method.delete: 'delete',
  Method.get: 'get',
  Method.patch: 'patch',
};
