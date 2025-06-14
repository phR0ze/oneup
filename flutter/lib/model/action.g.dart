// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Action _$ActionFromJson(Map<String, dynamic> json) => _Action(
      id: (json['id'] as num).toInt(),
      desc: json['desc'] as String,
      value: (json['value'] as num).toInt(),
      categoryId: (json['categoryId'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ActionToJson(_Action instance) => <String, dynamic>{
      'id': instance.id,
      'desc': instance.desc,
      'value': instance.value,
      'categoryId': instance.categoryId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
