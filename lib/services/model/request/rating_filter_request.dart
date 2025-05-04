import 'package:ludicapp/core/enums/completion_status.dart';
import 'package:ludicapp/core/enums/play_status.dart';

class RatingFilterRequest {
  final int? userId;
  final int? gameId;
  final bool? hasComment;
  final int? minRating;
  final int? maxRating;
  final PlayStatus? playStatus;
  final CompletionStatus? completionStatus;

  RatingFilterRequest({
    this.userId,
    this.gameId,
    this.hasComment,
    this.minRating,
    this.maxRating,
    this.playStatus,
    this.completionStatus,
  });

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};
    if (userId != null) {
      params['userId'] = userId.toString();
    }
    if (gameId != null) {
      params['gameId'] = gameId.toString();
    }
    if (hasComment != null) {
      params['hasComment'] = hasComment.toString();
    }
    if (minRating != null) {
      params['minRating'] = minRating.toString();
    }
    if (maxRating != null) {
      params['maxRating'] = maxRating.toString();
    }
    if (playStatus != null) {
      params['playStatus'] = playStatus!.toJson();
    }
    if (completionStatus != null) {
      params['completionStatus'] = completionStatus!.toJson();
    }
    return params;
  }
} 