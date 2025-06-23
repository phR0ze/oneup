import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_action.freezed.dart';
part 'api_action.g.dart';

@freezed
class ApiAction with _$ApiAction {
  const factory ApiAction({
    required int id,
    required String desc,
    required int value,
    required bool approved,
    @JsonKey(name: 'category_id') required int categoryId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _ApiAction;

  factory ApiAction.fromJson(Map<String, dynamic> json) => _$ApiActionFromJson(json);
}
