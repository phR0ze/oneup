// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ApiAction _$ApiActionFromJson(Map<String, dynamic> json) {
  return _ApiAction.fromJson(json);
}

/// @nodoc
mixin _$ApiAction {
  int get id => throw _privateConstructorUsedError;
  String get desc => throw _privateConstructorUsedError;
  int get value => throw _privateConstructorUsedError;
  @JsonKey(name: 'category_id')
  int get categoryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ApiAction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApiAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApiActionCopyWith<ApiAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiActionCopyWith<$Res> {
  factory $ApiActionCopyWith(ApiAction value, $Res Function(ApiAction) then) =
      _$ApiActionCopyWithImpl<$Res, ApiAction>;
  @useResult
  $Res call(
      {int id,
      String desc,
      int value,
      @JsonKey(name: 'category_id') int categoryId,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class _$ApiActionCopyWithImpl<$Res, $Val extends ApiAction>
    implements $ApiActionCopyWith<$Res> {
  _$ApiActionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApiAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? desc = null,
    Object? value = null,
    Object? categoryId = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      desc: null == desc
          ? _value.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApiActionImplCopyWith<$Res>
    implements $ApiActionCopyWith<$Res> {
  factory _$$ApiActionImplCopyWith(
          _$ApiActionImpl value, $Res Function(_$ApiActionImpl) then) =
      __$$ApiActionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String desc,
      int value,
      @JsonKey(name: 'category_id') int categoryId,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class __$$ApiActionImplCopyWithImpl<$Res>
    extends _$ApiActionCopyWithImpl<$Res, _$ApiActionImpl>
    implements _$$ApiActionImplCopyWith<$Res> {
  __$$ApiActionImplCopyWithImpl(
      _$ApiActionImpl _value, $Res Function(_$ApiActionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApiAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? desc = null,
    Object? value = null,
    Object? categoryId = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ApiActionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      desc: null == desc
          ? _value.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiActionImpl implements _ApiAction {
  const _$ApiActionImpl(
      {required this.id,
      required this.desc,
      required this.value,
      @JsonKey(name: 'category_id') required this.categoryId,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt});

  factory _$ApiActionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiActionImplFromJson(json);

  @override
  final int id;
  @override
  final String desc;
  @override
  final int value;
  @override
  @JsonKey(name: 'category_id')
  final int categoryId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ApiAction(id: $id, desc: $desc, value: $value, categoryId: $categoryId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiActionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.desc, desc) || other.desc == desc) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, desc, value, categoryId, createdAt, updatedAt);

  /// Create a copy of ApiAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiActionImplCopyWith<_$ApiActionImpl> get copyWith =>
      __$$ApiActionImplCopyWithImpl<_$ApiActionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiActionImplToJson(
      this,
    );
  }
}

abstract class _ApiAction implements ApiAction {
  const factory _ApiAction(
          {required final int id,
          required final String desc,
          required final int value,
          @JsonKey(name: 'category_id') required final int categoryId,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') required final DateTime updatedAt}) =
      _$ApiActionImpl;

  factory _ApiAction.fromJson(Map<String, dynamic> json) =
      _$ApiActionImpl.fromJson;

  @override
  int get id;
  @override
  String get desc;
  @override
  int get value;
  @override
  @JsonKey(name: 'category_id')
  int get categoryId;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// Create a copy of ApiAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiActionImplCopyWith<_$ApiActionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
