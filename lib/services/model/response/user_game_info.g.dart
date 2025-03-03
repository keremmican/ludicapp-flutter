// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_game_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserGameInfo _$UserGameInfoFromJson(Map<String, dynamic> json) => UserGameInfo(
      isSaved: json['isSaved'] as bool,
      isHid: json['isHid'] as bool,
      rating: (json['rating'] as num?)?.toInt(),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$UserGameInfoToJson(UserGameInfo instance) =>
    <String, dynamic>{
      'isSaved': instance.isSaved,
      'isHid': instance.isHid,
      'rating': instance.rating,
      'comment': instance.comment,
    };
