import 'package:freezed_annotation/freezed_annotation.dart';

part 'points.freezed.dart';
part 'points.g.dart';

@freezed
class Points with _$Points {
  const factory Points({
    required int id,
    required int value,
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'action_id') required int actionId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Points;

  factory Points.fromJson(Map<String, dynamic> json) => _$PointsFromJson(json);
}
