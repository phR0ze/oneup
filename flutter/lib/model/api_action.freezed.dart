// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApiAction {

 int get id; String get desc; int get value; bool get approved;@JsonKey(name: 'category_id') int get categoryId;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of ApiAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiActionCopyWith<ApiAction> get copyWith => _$ApiActionCopyWithImpl<ApiAction>(this as ApiAction, _$identity);

  /// Serializes this ApiAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiAction&&(identical(other.id, id) || other.id == id)&&(identical(other.desc, desc) || other.desc == desc)&&(identical(other.value, value) || other.value == value)&&(identical(other.approved, approved) || other.approved == approved)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,desc,value,approved,categoryId,createdAt,updatedAt);

@override
String toString() {
  return 'ApiAction(id: $id, desc: $desc, value: $value, approved: $approved, categoryId: $categoryId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ApiActionCopyWith<$Res>  {
  factory $ApiActionCopyWith(ApiAction value, $Res Function(ApiAction) _then) = _$ApiActionCopyWithImpl;
@useResult
$Res call({
 int id, String desc, int value, bool approved,@JsonKey(name: 'category_id') int categoryId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$ApiActionCopyWithImpl<$Res>
    implements $ApiActionCopyWith<$Res> {
  _$ApiActionCopyWithImpl(this._self, this._then);

  final ApiAction _self;
  final $Res Function(ApiAction) _then;

/// Create a copy of ApiAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? desc = null,Object? value = null,Object? approved = null,Object? categoryId = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,desc: null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiAction].
extension ApiActionPatterns on ApiAction {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiAction() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiAction value)  $default,){
final _that = this;
switch (_that) {
case _ApiAction():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiAction value)?  $default,){
final _that = this;
switch (_that) {
case _ApiAction() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String desc,  int value,  bool approved, @JsonKey(name: 'category_id')  int categoryId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiAction() when $default != null:
return $default(_that.id,_that.desc,_that.value,_that.approved,_that.categoryId,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String desc,  int value,  bool approved, @JsonKey(name: 'category_id')  int categoryId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ApiAction():
return $default(_that.id,_that.desc,_that.value,_that.approved,_that.categoryId,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String desc,  int value,  bool approved, @JsonKey(name: 'category_id')  int categoryId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ApiAction() when $default != null:
return $default(_that.id,_that.desc,_that.value,_that.approved,_that.categoryId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiAction implements ApiAction {
  const _ApiAction({required this.id, required this.desc, required this.value, required this.approved, @JsonKey(name: 'category_id') required this.categoryId, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _ApiAction.fromJson(Map<String, dynamic> json) => _$ApiActionFromJson(json);

@override final  int id;
@override final  String desc;
@override final  int value;
@override final  bool approved;
@override@JsonKey(name: 'category_id') final  int categoryId;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of ApiAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiActionCopyWith<_ApiAction> get copyWith => __$ApiActionCopyWithImpl<_ApiAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiAction&&(identical(other.id, id) || other.id == id)&&(identical(other.desc, desc) || other.desc == desc)&&(identical(other.value, value) || other.value == value)&&(identical(other.approved, approved) || other.approved == approved)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,desc,value,approved,categoryId,createdAt,updatedAt);

@override
String toString() {
  return 'ApiAction(id: $id, desc: $desc, value: $value, approved: $approved, categoryId: $categoryId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ApiActionCopyWith<$Res> implements $ApiActionCopyWith<$Res> {
  factory _$ApiActionCopyWith(_ApiAction value, $Res Function(_ApiAction) _then) = __$ApiActionCopyWithImpl;
@override @useResult
$Res call({
 int id, String desc, int value, bool approved,@JsonKey(name: 'category_id') int categoryId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$ApiActionCopyWithImpl<$Res>
    implements _$ApiActionCopyWith<$Res> {
  __$ApiActionCopyWithImpl(this._self, this._then);

  final _ApiAction _self;
  final $Res Function(_ApiAction) _then;

/// Create a copy of ApiAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? desc = null,Object? value = null,Object? approved = null,Object? categoryId = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ApiAction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,desc: null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
