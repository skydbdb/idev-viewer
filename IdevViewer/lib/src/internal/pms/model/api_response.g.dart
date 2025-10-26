// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApiResponseImpl _$$ApiResponseImplFromJson(Map<String, dynamic> json) =>
    _$ApiResponseImpl(
      result: json['result'],
      reason: json['reason'] as String?,
      field: json['field'] as String?,
      txid: json['txid'] as String?,
      serverTime: json['server_time'] as String?,
      responseTime: json['response_time'] as String?,
      data: json['data'],
    );

Map<String, dynamic> _$$ApiResponseImplToJson(_$ApiResponseImpl instance) =>
    <String, dynamic>{
      'result': instance.result,
      'reason': instance.reason,
      'field': instance.field,
      'txid': instance.txid,
      'server_time': instance.serverTime,
      'response_time': instance.responseTime,
      'data': instance.data,
    };
