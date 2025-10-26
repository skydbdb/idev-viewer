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

Map<String, dynamic> _$$BehaviorImplToJson(_$BehaviorImpl instance) =>
    <String, dynamic>{
      'type': _$TypeEnumMap[instance.type]!,
      if (_$MethodEnumMap[instance.method] case final value?) 'method': value,
      if (instance.uri case final value?) 'uri': value,
      if (instance.requiredParameter case final value?)
        'requiredParameter': value,
      if (instance.requiredTarget case final value?) 'requiredTarget': value,
      if (instance.permission case final value?) 'permission': value,
      if (instance.defaultParameter case final value?)
        'defaultParameter': value,
    };

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
