import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu.freezed.dart';
part 'menu.g.dart';

@freezed
class Menu with _$Menu {
  factory Menu({
    int? menuId,
    int? seq,
    int? parentId,
    int? templateId,
    int? commitId,
    String? menuNm,
    List<Menu>? menus,
    int? level,
    @JsonKey(name: 'useYn', defaultValue: 'Y')
    String? useYn,
    @JsonKey(name: 'isDel', defaultValue: 'N')
    String? isDel,
    @JsonKey(name: 'act', defaultValue: '')
    String? act,
    @JsonKey(name: 'eft', defaultValue: '')
    String? eft,
    @JsonKey(name: 'CUD', defaultValue: '')
    String? crud,
  }) = _Menu;

  factory Menu.fromJson(Map<String, dynamic>json) => _$MenuFromJson(json);
}
