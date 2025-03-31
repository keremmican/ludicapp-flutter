class UserGameActions {
  final bool? isSaved;
  final bool? isRated;
  final bool? isHidden;
  final int? userRating;
  final String? comment;

  const UserGameActions({
    this.isSaved,
    this.isRated,
    this.isHidden,
    this.userRating,
    this.comment,
  });

  factory UserGameActions.fromJson(Map<String, dynamic> json) {
    return UserGameActions(
      isSaved: json['saved'] as bool?,
      isRated: json['rating'] != null,
      isHidden: json['hid'] as bool?,
      userRating: json['rating'] as int?,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saved': isSaved,
      'rating': userRating,
      'hid': isHidden,
      'comment': comment,
    };
  }

  UserGameActions copyWith({
    bool? isSaved,
    bool? isRated,
    bool? isHidden,
    int? userRating,
    String? comment,
  }) {
    return UserGameActions(
      isSaved: isSaved ?? this.isSaved,
      isRated: isRated ?? this.isRated,
      isHidden: isHidden ?? this.isHidden,
      userRating: userRating ?? this.userRating,
      comment: comment ?? this.comment,
    );
  }

  @override
  String toString() {
    return 'UserGameActions(isSaved: $isSaved, isRated: $isRated, isHidden: $isHidden, userRating: $userRating, comment: $comment)';
  }
} 