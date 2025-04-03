// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_game_rating.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserGameRatingImpl _$$UserGameRatingImplFromJson(Map<String, dynamic> json) =>
    _$UserGameRatingImpl(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      gameId: (json['gameId'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      ratingDate: DateTime.parse(json['ratingDate'] as String),
    );

Map<String, dynamic> _$$UserGameRatingImplToJson(
        _$UserGameRatingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'gameId': instance.gameId,
      'rating': instance.rating,
      'comment': instance.comment,
      'ratingDate': instance.ratingDate.toIso8601String(),
    };
