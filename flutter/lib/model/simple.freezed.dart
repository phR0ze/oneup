// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'simple.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Simple _$SimpleFromJson(Map<String, dynamic> json) {
  return _Simple.fromJson(json);
}

/// @nodoc
mixin _$Simple {
  String get message => throw _privateConstructorUsedError;

  /// Serializes this Simple to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Simple
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SimpleCopyWith<Simple> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SimpleCopyWith<$Res> {
  factory $SimpleCopyWith(Simple value, $Res Function(Simple) then) =
      _$SimpleCopyWithImpl<$Res, Simple>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$SimpleCopyWithImpl<$Res, $Val extends Simple>
    implements $SimpleCopyWith<$Res> {
  _$SimpleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Simple
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_value.copyWith(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SimpleImplCopyWith<$Res> implements $SimpleCopyWith<$Res> {
  factory _$$SimpleImplCopyWith(
          _$SimpleImpl value, $Res Function(_$SimpleImpl) then) =
      __$$SimpleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$SimpleImplCopyWithImpl<$Res>
    extends _$SimpleCopyWithImpl<$Res, _$SimpleImpl>
    implements _$$SimpleImplCopyWith<$Res> {
  __$$SimpleImplCopyWithImpl(
      _$SimpleImpl _value, $Res Function(_$SimpleImpl) _then)
      : super(_value, _then);

  /// Create a copy of Simple
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$SimpleImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SimpleImpl implements _Simple {
  const _$SimpleImpl({required this.message});

  factory _$SimpleImpl.fromJson(Map<String, dynamic> json) =>
      _$$SimpleImplFromJson(json);

  @override
  final String message;

  @override
  String toString() {
    return 'Simple(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SimpleImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Simple
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SimpleImplCopyWith<_$SimpleImpl> get copyWith =>
      __$$SimpleImplCopyWithImpl<_$SimpleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SimpleImplToJson(
      this,
    );
  }
}

abstract class _Simple implements Simple {
  const factory _Simple({required final String message}) = _$SimpleImpl;

  factory _Simple.fromJson(Map<String, dynamic> json) = _$SimpleImpl.fromJson;

  @override
  String get message;

  /// Create a copy of Simple
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SimpleImplCopyWith<_$SimpleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
