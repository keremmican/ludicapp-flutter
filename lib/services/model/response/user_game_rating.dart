class UserGameRating {
  final int id;
  final int userId;
  final int gameId;
  final int rating;
  final String? comment;
  final DateTime ratingDate;

  UserGameRating({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.rating,
    this.comment,
    required this.ratingDate,
  });

  factory UserGameRating.fromJson(Map<String, dynamic> json) {
    return UserGameRating(
      id: json['id'] as int,
      userId: json['userId'] as int,
      gameId: json['gameId'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      ratingDate: DateTime.parse(json['ratingDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'gameId': gameId,
      'rating': rating,
      'comment': comment,
      'ratingDate': ratingDate.toIso8601String(),
    };
  }
} 