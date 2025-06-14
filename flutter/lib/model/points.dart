import 'package:freezed_annotation/freezed_annotation.dart';

part 'points.freezed.dart';
part 'points.g.dart';

@freezed
class Points with _$Points {
  const factory Points({
    required int id,
    required int value,
    required int userId,
    required int actionId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Points;

  factory Points.fromJson(Map<String, dynamic> json) => _$PointsFromJson(json);
}
