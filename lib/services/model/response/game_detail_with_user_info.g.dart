// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_detail_with_user_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameDetailWithUserInfo _$GameDetailWithUserInfoFromJson(
        Map<String, dynamic> json) =>
    GameDetailWithUserInfo(
      gameDetails:
          GameSummary.fromJson(json['gameDetails'] as Map<String, dynamic>),
      userActions:
          UserGameInfo.fromJson(json['userActions'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GameDetailWithUserInfoToJson(
        GameDetailWithUserInfo instance) =>
    <String, dynamic>{
      'gameDetails': instance.gameDetails,
      'userActions': instance.userActions,
    };
