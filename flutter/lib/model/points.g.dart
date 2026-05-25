// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Points _$PointsFromJson(Map<String, dynamic> json) => _Points(
  id: (json['id'] as num).toInt(),
  value: (json['value'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  actionId: (json['action_id'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PointsToJson(_Points instance) => <String, dynamic>{
  'id': instance.id,
  'value': instance.value,
  'user_id': instance.userId,
  'action_id': instance.actionId,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
