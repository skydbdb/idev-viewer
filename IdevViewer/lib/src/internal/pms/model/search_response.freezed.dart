// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SearchResponse _$SearchResponseFromJson(Map<String, dynamic> json) {
  return _SearchResponseImpl.fromJson(json);
}

/// @nodoc
mixin _$SearchResponse {
  List<dynamic> get rows => throw _privateConstructorUsedError;
  Map<String, List<CodeItem>>? get codes => throw _privateConstructorUsedError;

  /// Serializes this SearchResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchResponseCopyWith<SearchResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchResponseCopyWith<$Res> {
  factory $SearchResponseCopyWith(
          SearchResponse value, $Res Function(SearchResponse) then) =
      _$SearchResponseCopyWithImpl<$Res, SearchResponse>;
  @useResult
  $Res call({List<dynamic> rows, Map<String, List<CodeItem>>? codes});
}

/// @nodoc
class _$SearchResponseCopyWithImpl<$Res, $Val extends SearchResponse>
    implements $SearchResponseCopyWith<$Res> {
  _$SearchResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rows = null,
    Object? codes = freezed,
  }) {
    return _then(_value.copyWith(
      rows: null == rows
          ? _value.rows
          : rows // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      codes: freezed == codes
          ? _value.codes
          : codes // ignore: cast_nullable_to_non_nullable
              as Map<String, List<CodeItem>>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SearchResponseImplImplCopyWith<$Res>
    implements $SearchResponseCopyWith<$Res> {
  factory _$$SearchResponseImplImplCopyWith(_$SearchResponseImplImpl value,
          $Res Function(_$SearchResponseImplImpl) then) =
      __$$SearchResponseImplImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<dynamic> rows, Map<String, List<CodeItem>>? codes});
}

/// @nodoc
class __$$SearchResponseImplImplCopyWithImpl<$Res>
    extends _$SearchResponseCopyWithImpl<$Res, _$SearchResponseImplImpl>
    implements _$$SearchResponseImplImplCopyWith<$Res> {
  __$$SearchResponseImplImplCopyWithImpl(_$SearchResponseImplImpl _value,
      $Res Function(_$SearchResponseImplImpl) _then)
      : super(_value, _then);

  /// Create a copy of SearchResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rows = null,
    Object? codes = freezed,
  }) {
    return _then(_$SearchResponseImplImpl(
      rows: null == rows
          ? _value._rows
          : rows // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      codes: freezed == codes
          ? _value._codes
          : codes // ignore: cast_nullable_to_non_nullable
              as Map<String, List<CodeItem>>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchResponseImplImpl implements _SearchResponseImpl {
  const _$SearchResponseImplImpl(
      {final List<dynamic> rows = const [],
      final Map<String, List<CodeItem>>? codes})
      : _rows = rows,
        _codes = codes;

  factory _$SearchResponseImplImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchResponseImplImplFromJson(json);

  final List<dynamic> _rows;
  @override
  @JsonKey()
  List<dynamic> get rows {
    if (_rows is EqualUnmodifiableListView) return _rows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rows);
  }

  final Map<String, List<CodeItem>>? _codes;
  @override
  Map<String, List<CodeItem>>? get codes {
    final value = _codes;
    if (value == null) return null;
    if (_codes is EqualUnmodifiableMapView) return _codes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'SearchResponse(rows: $rows, codes: $codes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchResponseImplImpl &&
            const DeepCollectionEquality().equals(other._rows, _rows) &&
            const DeepCollectionEquality().equals(other._codes, _codes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_rows),
      const DeepCollectionEquality().hash(_codes));

  /// Create a copy of SearchResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchResponseImplImplCopyWith<_$SearchResponseImplImpl> get copyWith =>
      __$$SearchResponseImplImplCopyWithImpl<_$SearchResponseImplImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchResponseImplImplToJson(
      this,
    );
  }
}

abstract class _SearchResponseImpl implements SearchResponse {
  const factory _SearchResponseImpl(
      {final List<dynamic> rows,
      final Map<String, List<CodeItem>>? codes}) = _$SearchResponseImplImpl;

  factory _SearchResponseImpl.fromJson(Map<String, dynamic> json) =
      _$SearchResponseImplImpl.fromJson;

  @override
  List<dynamic> get rows;
  @override
  Map<String, List<CodeItem>>? get codes;

  /// Create a copy of SearchResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchResponseImplImplCopyWith<_$SearchResponseImplImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CodeItem _$CodeItemFromJson(Map<String, dynamic> json) {
  return _CodeItemImpl.fromJson(json);
}

/// @nodoc
mixin _$CodeItem {
  String get name => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;

  /// Serializes this CodeItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CodeItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CodeItemCopyWith<CodeItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CodeItemCopyWith<$Res> {
  factory $CodeItemCopyWith(CodeItem value, $Res Function(CodeItem) then) =
      _$CodeItemCopyWithImpl<$Res, CodeItem>;
  @useResult
  $Res call({String name, String value});
}

/// @nodoc
class _$CodeItemCopyWithImpl<$Res, $Val extends CodeItem>
    implements $CodeItemCopyWith<$Res> {
  _$CodeItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CodeItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? value = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CodeItemImplImplCopyWith<$Res>
    implements $CodeItemCopyWith<$Res> {
  factory _$$CodeItemImplImplCopyWith(
          _$CodeItemImplImpl value, $Res Function(_$CodeItemImplImpl) then) =
      __$$CodeItemImplImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String value});
}

/// @nodoc
class __$$CodeItemImplImplCopyWithImpl<$Res>
    extends _$CodeItemCopyWithImpl<$Res, _$CodeItemImplImpl>
    implements _$$CodeItemImplImplCopyWith<$Res> {
  __$$CodeItemImplImplCopyWithImpl(
      _$CodeItemImplImpl _value, $Res Function(_$CodeItemImplImpl) _then)
      : super(_value, _then);

  /// Create a copy of CodeItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? value = null,
  }) {
    return _then(_$CodeItemImplImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CodeItemImplImpl implements _CodeItemImpl {
  const _$CodeItemImplImpl({required this.name, required this.value});

  factory _$CodeItemImplImpl.fromJson(Map<String, dynamic> json) =>
      _$$CodeItemImplImplFromJson(json);

  @override
  final String name;
  @override
  final String value;

  @override
  String toString() {
    return 'CodeItem(name: $name, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CodeItemImplImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, value);

  /// Create a copy of CodeItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CodeItemImplImplCopyWith<_$CodeItemImplImpl> get copyWith =>
      __$$CodeItemImplImplCopyWithImpl<_$CodeItemImplImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CodeItemImplImplToJson(
      this,
    );
  }
}

abstract class _CodeItemImpl implements CodeItem {
  const factory _CodeItemImpl(
      {required final String name,
      required final String value}) = _$CodeItemImplImpl;

  factory _CodeItemImpl.fromJson(Map<String, dynamic> json) =
      _$CodeItemImplImpl.fromJson;

  @override
  String get name;
  @override
  String get value;

  /// Create a copy of CodeItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CodeItemImplImplCopyWith<_$CodeItemImplImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
