import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_game_rating.freezed.dart';
part 'user_game_rating.g.dart';

@freezed
class UserGameRating with _$UserGameRating {
  const factory UserGameRating({
    required int id,
    required int userId,
    required int gameId,
    required int rating,
    String? comment,
    required DateTime ratingDate,
  }) = _UserGameRating;

  factory UserGameRating.fromJson(Map<String, dynamic> json) =>
      _$UserGameRatingFromJson(json);
} 