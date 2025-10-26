// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SearchResponseImplImpl _$$SearchResponseImplImplFromJson(
        Map<String, dynamic> json) =>
    _$SearchResponseImplImpl(
      rows: json['rows'] as List<dynamic>? ?? const [],
      codes: (json['codes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => CodeItem.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
    );

Map<String, dynamic> _$$SearchResponseImplImplToJson(
        _$SearchResponseImplImpl instance) =>
    <String, dynamic>{
      'rows': instance.rows,
      'codes': instance.codes,
    };

_$CodeItemImplImpl _$$CodeItemImplImplFromJson(Map<String, dynamic> json) =>
    _$CodeItemImplImpl(
      name: json['name'] as String,
      value: json['value'] as String,
    );

Map<String, dynamic> _$$CodeItemImplImplToJson(_$CodeItemImplImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'value': instance.value,
    };
