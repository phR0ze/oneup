import 'package:freezed_annotation/freezed_annotation.dart';

part 'simple.freezed.dart';
part 'simple.g.dart';

@freezed
class Simple with _$Simple {
  const factory Simple({
    required String message,
  }) = _Simple;

  factory Simple.fromJson(Map<String, dynamic> json) => _$SimpleFromJson(json);
} 
 