// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_game_library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserGameLibrary _$UserGameLibraryFromJson(Map<String, dynamic> json) =>
    UserGameLibrary(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      type: json['type'] as String,
      userId: (json['userId'] as num).toInt(),
      gameIds: (json['gameIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$UserGameLibraryToJson(UserGameLibrary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': instance.type,
      'userId': instance.userId,
      'gameIds': instance.gameIds,
    };
