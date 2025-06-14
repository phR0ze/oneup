// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'apierr.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ApiErr _$ApiErrFromJson(Map<String, dynamic> json) {
  return _ApiErr.fromJson(json);
}

/// @nodoc
mixin _$ApiErr {
  String get message => throw _privateConstructorUsedError;

  /// Serializes this ApiErr to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApiErr
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApiErrCopyWith<ApiErr> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiErrCopyWith<$Res> {
  factory $ApiErrCopyWith(ApiErr value, $Res Function(ApiErr) then) =
      _$ApiErrCopyWithImpl<$Res, ApiErr>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$ApiErrCopyWithImpl<$Res, $Val extends ApiErr>
    implements $ApiErrCopyWith<$Res> {
  _$ApiErrCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApiErr
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
abstract class _$$ApiErrImplCopyWith<$Res> implements $ApiErrCopyWith<$Res> {
  factory _$$ApiErrImplCopyWith(
          _$ApiErrImpl value, $Res Function(_$ApiErrImpl) then) =
      __$$ApiErrImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ApiErrImplCopyWithImpl<$Res>
    extends _$ApiErrCopyWithImpl<$Res, _$ApiErrImpl>
    implements _$$ApiErrImplCopyWith<$Res> {
  __$$ApiErrImplCopyWithImpl(
      _$ApiErrImpl _value, $Res Function(_$ApiErrImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApiErr
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ApiErrImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiErrImpl implements _ApiErr {
  const _$ApiErrImpl({required this.message});

  factory _$ApiErrImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiErrImplFromJson(json);

  @override
  final String message;

  @override
  String toString() {
    return 'ApiErr(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiErrImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of ApiErr
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiErrImplCopyWith<_$ApiErrImpl> get copyWith =>
      __$$ApiErrImplCopyWithImpl<_$ApiErrImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiErrImplToJson(
      this,
    );
  }
}

abstract class _ApiErr implements ApiErr {
  const factory _ApiErr({required final String message}) = _$ApiErrImpl;

  factory _ApiErr.fromJson(Map<String, dynamic> json) = _$ApiErrImpl.fromJson;

  @override
  String get message;

  /// Create a copy of ApiErr
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiErrImplCopyWith<_$ApiErrImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
