// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Menu _$MenuFromJson(Map<String, dynamic> json) {
  return _Menu.fromJson(json);
}

/// @nodoc
mixin _$Menu {
  int? get menuId => throw _privateConstructorUsedError;
  int? get seq => throw _privateConstructorUsedError;
  int? get parentId => throw _privateConstructorUsedError;
  int? get templateId => throw _privateConstructorUsedError;
  int? get commitId => throw _privateConstructorUsedError;
  String? get menuNm => throw _privateConstructorUsedError;
  List<Menu>? get menus => throw _privateConstructorUsedError;
  int? get level => throw _privateConstructorUsedError;
  @JsonKey(name: 'useYn', defaultValue: 'Y')
  String? get useYn => throw _privateConstructorUsedError;
  @JsonKey(name: 'isDel', defaultValue: 'N')
  String? get isDel => throw _privateConstructorUsedError;
  @JsonKey(name: 'act', defaultValue: '')
  String? get act => throw _privateConstructorUsedError;
  @JsonKey(name: 'eft', defaultValue: '')
  String? get eft => throw _privateConstructorUsedError;
  @JsonKey(name: 'CUD', defaultValue: '')
  String? get crud => throw _privateConstructorUsedError;

  /// Serializes this Menu to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Menu
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuCopyWith<Menu> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuCopyWith<$Res> {
  factory $MenuCopyWith(Menu value, $Res Function(Menu) then) =
      _$MenuCopyWithImpl<$Res, Menu>;
  @useResult
  $Res call(
      {int? menuId,
      int? seq,
      int? parentId,
      int? templateId,
      int? commitId,
      String? menuNm,
      List<Menu>? menus,
      int? level,
      @JsonKey(name: 'useYn', defaultValue: 'Y') String? useYn,
      @JsonKey(name: 'isDel', defaultValue: 'N') String? isDel,
      @JsonKey(name: 'act', defaultValue: '') String? act,
      @JsonKey(name: 'eft', defaultValue: '') String? eft,
      @JsonKey(name: 'CUD', defaultValue: '') String? crud});
}

/// @nodoc
class _$MenuCopyWithImpl<$Res, $Val extends Menu>
    implements $MenuCopyWith<$Res> {
  _$MenuCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Menu
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? menuId = freezed,
    Object? seq = freezed,
    Object? parentId = freezed,
    Object? templateId = freezed,
    Object? commitId = freezed,
    Object? menuNm = freezed,
    Object? menus = freezed,
    Object? level = freezed,
    Object? useYn = freezed,
    Object? isDel = freezed,
    Object? act = freezed,
    Object? eft = freezed,
    Object? crud = freezed,
  }) {
    return _then(_value.copyWith(
      menuId: freezed == menuId
          ? _value.menuId
          : menuId // ignore: cast_nullable_to_non_nullable
              as int?,
      seq: freezed == seq
          ? _value.seq
          : seq // ignore: cast_nullable_to_non_nullable
              as int?,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as int?,
      templateId: freezed == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as int?,
      commitId: freezed == commitId
          ? _value.commitId
          : commitId // ignore: cast_nullable_to_non_nullable
              as int?,
      menuNm: freezed == menuNm
          ? _value.menuNm
          : menuNm // ignore: cast_nullable_to_non_nullable
              as String?,
      menus: freezed == menus
          ? _value.menus
          : menus // ignore: cast_nullable_to_non_nullable
              as List<Menu>?,
      level: freezed == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int?,
      useYn: freezed == useYn
          ? _value.useYn
          : useYn // ignore: cast_nullable_to_non_nullable
              as String?,
      isDel: freezed == isDel
          ? _value.isDel
          : isDel // ignore: cast_nullable_to_non_nullable
              as String?,
      act: freezed == act
          ? _value.act
          : act // ignore: cast_nullable_to_non_nullable
              as String?,
      eft: freezed == eft
          ? _value.eft
          : eft // ignore: cast_nullable_to_non_nullable
              as String?,
      crud: freezed == crud
          ? _value.crud
          : crud // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MenuImplCopyWith<$Res> implements $MenuCopyWith<$Res> {
  factory _$$MenuImplCopyWith(
          _$MenuImpl value, $Res Function(_$MenuImpl) then) =
      __$$MenuImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? menuId,
      int? seq,
      int? parentId,
      int? templateId,
      int? commitId,
      String? menuNm,
      List<Menu>? menus,
      int? level,
      @JsonKey(name: 'useYn', defaultValue: 'Y') String? useYn,
      @JsonKey(name: 'isDel', defaultValue: 'N') String? isDel,
      @JsonKey(name: 'act', defaultValue: '') String? act,
      @JsonKey(name: 'eft', defaultValue: '') String? eft,
      @JsonKey(name: 'CUD', defaultValue: '') String? crud});
}

/// @nodoc
class __$$MenuImplCopyWithImpl<$Res>
    extends _$MenuCopyWithImpl<$Res, _$MenuImpl>
    implements _$$MenuImplCopyWith<$Res> {
  __$$MenuImplCopyWithImpl(_$MenuImpl _value, $Res Function(_$MenuImpl) _then)
      : super(_value, _then);

  /// Create a copy of Menu
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? menuId = freezed,
    Object? seq = freezed,
    Object? parentId = freezed,
    Object? templateId = freezed,
    Object? commitId = freezed,
    Object? menuNm = freezed,
    Object? menus = freezed,
    Object? level = freezed,
    Object? useYn = freezed,
    Object? isDel = freezed,
    Object? act = freezed,
    Object? eft = freezed,
    Object? crud = freezed,
  }) {
    return _then(_$MenuImpl(
      menuId: freezed == menuId
          ? _value.menuId
          : menuId // ignore: cast_nullable_to_non_nullable
              as int?,
      seq: freezed == seq
          ? _value.seq
          : seq // ignore: cast_nullable_to_non_nullable
              as int?,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as int?,
      templateId: freezed == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as int?,
      commitId: freezed == commitId
          ? _value.commitId
          : commitId // ignore: cast_nullable_to_non_nullable
              as int?,
      menuNm: freezed == menuNm
          ? _value.menuNm
          : menuNm // ignore: cast_nullable_to_non_nullable
              as String?,
      menus: freezed == menus
          ? _value._menus
          : menus // ignore: cast_nullable_to_non_nullable
              as List<Menu>?,
      level: freezed == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int?,
      useYn: freezed == useYn
          ? _value.useYn
          : useYn // ignore: cast_nullable_to_non_nullable
              as String?,
      isDel: freezed == isDel
          ? _value.isDel
          : isDel // ignore: cast_nullable_to_non_nullable
              as String?,
      act: freezed == act
          ? _value.act
          : act // ignore: cast_nullable_to_non_nullable
              as String?,
      eft: freezed == eft
          ? _value.eft
          : eft // ignore: cast_nullable_to_non_nullable
              as String?,
      crud: freezed == crud
          ? _value.crud
          : crud // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuImpl implements _Menu {
  _$MenuImpl(
      {this.menuId,
      this.seq,
      this.parentId,
      this.templateId,
      this.commitId,
      this.menuNm,
      final List<Menu>? menus,
      this.level,
      @JsonKey(name: 'useYn', defaultValue: 'Y') this.useYn,
      @JsonKey(name: 'isDel', defaultValue: 'N') this.isDel,
      @JsonKey(name: 'act', defaultValue: '') this.act,
      @JsonKey(name: 'eft', defaultValue: '') this.eft,
      @JsonKey(name: 'CUD', defaultValue: '') this.crud})
      : _menus = menus;

  factory _$MenuImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuImplFromJson(json);

  @override
  final int? menuId;
  @override
  final int? seq;
  @override
  final int? parentId;
  @override
  final int? templateId;
  @override
  final int? commitId;
  @override
  final String? menuNm;
  final List<Menu>? _menus;
  @override
  List<Menu>? get menus {
    final value = _menus;
    if (value == null) return null;
    if (_menus is EqualUnmodifiableListView) return _menus;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? level;
  @override
  @JsonKey(name: 'useYn', defaultValue: 'Y')
  final String? useYn;
  @override
  @JsonKey(name: 'isDel', defaultValue: 'N')
  final String? isDel;
  @override
  @JsonKey(name: 'act', defaultValue: '')
  final String? act;
  @override
  @JsonKey(name: 'eft', defaultValue: '')
  final String? eft;
  @override
  @JsonKey(name: 'CUD', defaultValue: '')
  final String? crud;

  @override
  String toString() {
    return 'Menu(menuId: $menuId, seq: $seq, parentId: $parentId, templateId: $templateId, commitId: $commitId, menuNm: $menuNm, menus: $menus, level: $level, useYn: $useYn, isDel: $isDel, act: $act, eft: $eft, crud: $crud)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuImpl &&
            (identical(other.menuId, menuId) || other.menuId == menuId) &&
            (identical(other.seq, seq) || other.seq == seq) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.commitId, commitId) ||
                other.commitId == commitId) &&
            (identical(other.menuNm, menuNm) || other.menuNm == menuNm) &&
            const DeepCollectionEquality().equals(other._menus, _menus) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.useYn, useYn) || other.useYn == useYn) &&
            (identical(other.isDel, isDel) || other.isDel == isDel) &&
            (identical(other.act, act) || other.act == act) &&
            (identical(other.eft, eft) || other.eft == eft) &&
            (identical(other.crud, crud) || other.crud == crud));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      menuId,
      seq,
      parentId,
      templateId,
      commitId,
      menuNm,
      const DeepCollectionEquality().hash(_menus),
      level,
      useYn,
      isDel,
      act,
      eft,
      crud);

  /// Create a copy of Menu
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuImplCopyWith<_$MenuImpl> get copyWith =>
      __$$MenuImplCopyWithImpl<_$MenuImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuImplToJson(
      this,
    );
  }
}

abstract class _Menu implements Menu {
  factory _Menu(
      {final int? menuId,
      final int? seq,
      final int? parentId,
      final int? templateId,
      final int? commitId,
      final String? menuNm,
      final List<Menu>? menus,
      final int? level,
      @JsonKey(name: 'useYn', defaultValue: 'Y') final String? useYn,
      @JsonKey(name: 'isDel', defaultValue: 'N') final String? isDel,
      @JsonKey(name: 'act', defaultValue: '') final String? act,
      @JsonKey(name: 'eft', defaultValue: '') final String? eft,
      @JsonKey(name: 'CUD', defaultValue: '') final String? crud}) = _$MenuImpl;

  factory _Menu.fromJson(Map<String, dynamic> json) = _$MenuImpl.fromJson;

  @override
  int? get menuId;
  @override
  int? get seq;
  @override
  int? get parentId;
  @override
  int? get templateId;
  @override
  int? get commitId;
  @override
  String? get menuNm;
  @override
  List<Menu>? get menus;
  @override
  int? get level;
  @override
  @JsonKey(name: 'useYn', defaultValue: 'Y')
  String? get useYn;
  @override
  @JsonKey(name: 'isDel', defaultValue: 'N')
  String? get isDel;
  @override
  @JsonKey(name: 'act', defaultValue: '')
  String? get act;
  @override
  @JsonKey(name: 'eft', defaultValue: '')
  String? get eft;
  @override
  @JsonKey(name: 'CUD', defaultValue: '')
  String? get crud;

  /// Create a copy of Menu
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuImplCopyWith<_$MenuImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
