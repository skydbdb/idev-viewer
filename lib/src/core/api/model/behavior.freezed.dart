// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'behavior.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Behavior _$BehaviorFromJson(Map<String, dynamic> json) {
  return _Behavior.fromJson(json);
}

/// @nodoc
mixin _$Behavior {
  Type get type => throw _privateConstructorUsedError;
  Method? get method => throw _privateConstructorUsedError;
  String? get uri => throw _privateConstructorUsedError;
  List<String>? get requiredParameter => throw _privateConstructorUsedError;
  String? get requiredTarget => throw _privateConstructorUsedError;
  List<int>? get permission => throw _privateConstructorUsedError;
  Map<String, dynamic>? get defaultParameter =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BehaviorCopyWith<Behavior> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BehaviorCopyWith<$Res> {
  factory $BehaviorCopyWith(Behavior value, $Res Function(Behavior) then) =
      _$BehaviorCopyWithImpl<$Res, Behavior>;
  @useResult
  $Res call(
      {Type type,
      Method? method,
      String? uri,
      List<String>? requiredParameter,
      String? requiredTarget,
      List<int>? permission,
      Map<String, dynamic>? defaultParameter});
}

/// @nodoc
class _$BehaviorCopyWithImpl<$Res, $Val extends Behavior>
    implements $BehaviorCopyWith<$Res> {
  _$BehaviorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? method = freezed,
    Object? uri = freezed,
    Object? requiredParameter = freezed,
    Object? requiredTarget = freezed,
    Object? permission = freezed,
    Object? defaultParameter = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as Type,
      method: freezed == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as Method?,
      uri: freezed == uri
          ? _value.uri
          : uri // ignore: cast_nullable_to_non_nullable
              as String?,
      requiredParameter: freezed == requiredParameter
          ? _value.requiredParameter
          : requiredParameter // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      requiredTarget: freezed == requiredTarget
          ? _value.requiredTarget
          : requiredTarget // ignore: cast_nullable_to_non_nullable
              as String?,
      permission: freezed == permission
          ? _value.permission
          : permission // ignore: cast_nullable_to_non_nullable
              as List<int>?,
      defaultParameter: freezed == defaultParameter
          ? _value.defaultParameter
          : defaultParameter // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BehaviorImplCopyWith<$Res>
    implements $BehaviorCopyWith<$Res> {
  factory _$$BehaviorImplCopyWith(
          _$BehaviorImpl value, $Res Function(_$BehaviorImpl) then) =
      __$$BehaviorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Type type,
      Method? method,
      String? uri,
      List<String>? requiredParameter,
      String? requiredTarget,
      List<int>? permission,
      Map<String, dynamic>? defaultParameter});
}

/// @nodoc
class __$$BehaviorImplCopyWithImpl<$Res>
    extends _$BehaviorCopyWithImpl<$Res, _$BehaviorImpl>
    implements _$$BehaviorImplCopyWith<$Res> {
  __$$BehaviorImplCopyWithImpl(
      _$BehaviorImpl _value, $Res Function(_$BehaviorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? method = freezed,
    Object? uri = freezed,
    Object? requiredParameter = freezed,
    Object? requiredTarget = freezed,
    Object? permission = freezed,
    Object? defaultParameter = freezed,
  }) {
    return _then(_$BehaviorImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as Type,
      method: freezed == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as Method?,
      uri: freezed == uri
          ? _value.uri
          : uri // ignore: cast_nullable_to_non_nullable
              as String?,
      requiredParameter: freezed == requiredParameter
          ? _value._requiredParameter
          : requiredParameter // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      requiredTarget: freezed == requiredTarget
          ? _value.requiredTarget
          : requiredTarget // ignore: cast_nullable_to_non_nullable
              as String?,
      permission: freezed == permission
          ? _value._permission
          : permission // ignore: cast_nullable_to_non_nullable
              as List<int>?,
      defaultParameter: freezed == defaultParameter
          ? _value._defaultParameter
          : defaultParameter // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, includeIfNull: false)
@JsonKey(name: 'behavior')
class _$BehaviorImpl extends _Behavior {
  _$BehaviorImpl(
      {required this.type,
      this.method,
      this.uri,
      final List<String>? requiredParameter,
      this.requiredTarget,
      final List<int>? permission,
      final Map<String, dynamic>? defaultParameter})
      : _requiredParameter = requiredParameter,
        _permission = permission,
        _defaultParameter = defaultParameter,
        super._();

  factory _$BehaviorImpl.fromJson(Map<String, dynamic> json) =>
      _$$BehaviorImplFromJson(json);

  @override
  final Type type;
  @override
  final Method? method;
  @override
  final String? uri;
  final List<String>? _requiredParameter;
  @override
  List<String>? get requiredParameter {
    final value = _requiredParameter;
    if (value == null) return null;
    if (_requiredParameter is EqualUnmodifiableListView)
      return _requiredParameter;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? requiredTarget;
  final List<int>? _permission;
  @override
  List<int>? get permission {
    final value = _permission;
    if (value == null) return null;
    if (_permission is EqualUnmodifiableListView) return _permission;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _defaultParameter;
  @override
  Map<String, dynamic>? get defaultParameter {
    final value = _defaultParameter;
    if (value == null) return null;
    if (_defaultParameter is EqualUnmodifiableMapView) return _defaultParameter;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Behavior(type: $type, method: $method, uri: $uri, requiredParameter: $requiredParameter, requiredTarget: $requiredTarget, permission: $permission, defaultParameter: $defaultParameter)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BehaviorImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.uri, uri) || other.uri == uri) &&
            const DeepCollectionEquality()
                .equals(other._requiredParameter, _requiredParameter) &&
            (identical(other.requiredTarget, requiredTarget) ||
                other.requiredTarget == requiredTarget) &&
            const DeepCollectionEquality()
                .equals(other._permission, _permission) &&
            const DeepCollectionEquality()
                .equals(other._defaultParameter, _defaultParameter));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      method,
      uri,
      const DeepCollectionEquality().hash(_requiredParameter),
      requiredTarget,
      const DeepCollectionEquality().hash(_permission),
      const DeepCollectionEquality().hash(_defaultParameter));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BehaviorImplCopyWith<_$BehaviorImpl> get copyWith =>
      __$$BehaviorImplCopyWithImpl<_$BehaviorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BehaviorImplToJson(
      this,
    );
  }
}

abstract class _Behavior extends Behavior {
  factory _Behavior(
      {required final Type type,
      final Method? method,
      final String? uri,
      final List<String>? requiredParameter,
      final String? requiredTarget,
      final List<int>? permission,
      final Map<String, dynamic>? defaultParameter}) = _$BehaviorImpl;
  _Behavior._() : super._();

  factory _Behavior.fromJson(Map<String, dynamic> json) =
      _$BehaviorImpl.fromJson;

  @override
  Type get type;
  @override
  Method? get method;
  @override
  String? get uri;
  @override
  List<String>? get requiredParameter;
  @override
  String? get requiredTarget;
  @override
  List<int>? get permission;
  @override
  Map<String, dynamic>? get defaultParameter;
  @override
  @JsonKey(ignore: true)
  _$$BehaviorImplCopyWith<_$BehaviorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
