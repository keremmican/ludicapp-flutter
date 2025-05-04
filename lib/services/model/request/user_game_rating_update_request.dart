import 'package:ludicapp/core/enums/completion_status.dart';
import 'package:ludicapp/core/enums/play_status.dart';

class UserGameRatingUpdateRequest {
  final int gameId;
  final int? rating;
  final String? comment;
  final PlayStatus? playStatus;
  final CompletionStatus? completionStatus;
  final int? playtimeInMinutes;

  UserGameRatingUpdateRequest({
    required this.gameId,
    this.rating,
    this.comment,
    this.playStatus,
    this.completionStatus,
    this.playtimeInMinutes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'gameId': gameId,
    };
    if (rating != null) {
      data['rating'] = rating;
    }
    // Include comment even if it's null to allow clearing it
    data['comment'] = comment; 
    
    // Her zaman playStatus değerini gönder, null değilse
    if (playStatus != null) {
      // Direkt enum string değerini gönder
      data['playStatus'] = playStatus!.toJson();
    }
    
    // Her zaman completionStatus değerini gönder, null değilse
    if (completionStatus != null) {
      // Direkt enum string değerini gönder
      data['completionStatus'] = completionStatus!.toJson();
    }
    
    if (playtimeInMinutes != null) {
      data['playtimeInMinutes'] = playtimeInMinutes;
    }
    
    return data;
  }
} 