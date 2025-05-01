class RatingFilterRequest {
  final bool? hasComment;
  final int? minRating;
  final int? maxRating;
  final int? gameId;

  RatingFilterRequest({
    this.hasComment,
    this.minRating,
    this.maxRating,
    this.gameId,
  });

  Map<String, String> toQueryParameters() {
    final Map<String, String> params = {};
    
    if (hasComment != null) {
      params['hasComment'] = hasComment.toString();
    }
    
    if (minRating != null) {
      params['minRating'] = minRating.toString();
    }
    
    if (maxRating != null) {
      params['maxRating'] = maxRating.toString();
    }
    
    if (gameId != null) {
      params['gameId'] = gameId.toString();
    }
    
    return params;
  }
} 