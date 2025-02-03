import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_light_response.freezed.dart';
part 'user_light_response.g.dart';

@freezed
class UserLightResponse with _$UserLightResponse {
  const factory UserLightResponse({
    required int id,
    required String username,
  }) = _UserLightResponse;

  factory UserLightResponse.fromJson(Map<String, dynamic> json) =>
      _$UserLightResponseFromJson(json);
} 