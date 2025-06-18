// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApiActionImpl _$$ApiActionImplFromJson(Map<String, dynamic> json) =>
    _$ApiActionImpl(
      id: (json['id'] as num).toInt(),
      desc: json['desc'] as String,
      value: (json['value'] as num).toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ApiActionImplToJson(_$ApiActionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'desc': instance.desc,
      'value': instance.value,
      'category_id': instance.categoryId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
