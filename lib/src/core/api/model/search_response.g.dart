// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SearchResponseImpl _$$SearchResponseImplFromJson(Map<String, dynamic> json) =>
    _$SearchResponseImpl(
      rows: json['result'] == null ? [] : toList(json['result']),
      codes: parser(json['code'] as Map<String, dynamic>?),
    );

Map<String, dynamic> _$$SearchResponseImplToJson(
        _$SearchResponseImpl instance) =>
    <String, dynamic>{
      'result': instance.rows,
      'code': instance.codes?.map((k, e) => MapEntry(
          k,
          e
              .map((e) => <String, dynamic>{
                    'name': e.name,
                    'value': e.value,
                  })
              .toList())),
    };
