import 'package:freezed_annotation/freezed_annotation.dart';

part 'apierr.freezed.dart';
part 'apierr.g.dart';

@freezed
class ApiErr with _$ApiErr {
  const factory ApiErr({
    required String message,
  }) = _ApiErr;

  factory ApiErr.fromJson(Map<String, dynamic> json) => _$ApiErrFromJson(json);
}