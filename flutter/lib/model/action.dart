import 'package:freezed_annotation/freezed_annotation.dart';

part 'action.freezed.dart';
part 'action.g.dart';

/// Using a wonky name here to avoid conflict with the Action class.
@freezed
class Action with _$Action {
  const factory Action({
    required int id,
    required String desc,
    required int value,
    required int categoryId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Action;

  factory Action.fromJson(Map<String, dynamic> json) => _$ActionFromJson(json);
}
