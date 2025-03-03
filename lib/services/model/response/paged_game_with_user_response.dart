import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/game_detail_with_user_info.dart';

class PagedGameWithUserResponse {
  final List<GameDetailWithUserInfo> content;
  final bool? last;
  final int? totalElements;
  final int? totalPages;
  final int? size;
  final int? number;
  final bool? first;
  final int? numberOfElements;
  final bool? empty;

  PagedGameWithUserResponse({
    required this.content,
    this.last,
    this.totalElements,
    this.totalPages,
    this.size,
    this.number,
    this.first,
    this.numberOfElements,
    this.empty,
  });

  factory PagedGameWithUserResponse.fromJson(Map<String, dynamic> json) {
    return PagedGameWithUserResponse(
      content: (json['content'] as List<dynamic>?)
          ?.map((e) => GameDetailWithUserInfo.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      last: json['last'] as bool?,
      totalElements: json['totalElements'] as int?,
      totalPages: json['totalPages'] as int?,
      size: json['size'] as int?,
      number: json['number'] as int?,
      first: json['first'] as bool?,
      numberOfElements: json['numberOfElements'] as int?,
      empty: json['empty'] as bool?,
    );
  }
}