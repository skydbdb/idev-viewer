// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MenuImpl _$$MenuImplFromJson(Map<String, dynamic> json) => _$MenuImpl(
      menuId: (json['menuId'] as num?)?.toInt(),
      seq: (json['seq'] as num?)?.toInt(),
      parentId: (json['parentId'] as num?)?.toInt(),
      templateId: (json['templateId'] as num?)?.toInt(),
      commitId: (json['commitId'] as num?)?.toInt(),
      menuNm: json['menuNm'] as String?,
      menus: (json['menus'] as List<dynamic>?)
          ?.map((e) => Menu.fromJson(e as Map<String, dynamic>))
          .toList(),
      level: (json['level'] as num?)?.toInt(),
      useYn: json['useYn'] as String? ?? 'Y',
      isDel: json['isDel'] as String? ?? 'N',
      act: json['act'] as String? ?? '',
      eft: json['eft'] as String? ?? '',
      crud: json['CUD'] as String? ?? '',
    );

Map<String, dynamic> _$$MenuImplToJson(_$MenuImpl instance) =>
    <String, dynamic>{
      'menuId': instance.menuId,
      'seq': instance.seq,
      'parentId': instance.parentId,
      'templateId': instance.templateId,
      'commitId': instance.commitId,
      'menuNm': instance.menuNm,
      'menus': instance.menus,
      'level': instance.level,
      'useYn': instance.useYn,
      'isDel': instance.isDel,
      'act': instance.act,
      'eft': instance.eft,
      'CUD': instance.crud,
    };
