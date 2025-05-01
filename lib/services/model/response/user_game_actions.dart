class UserGameActions {
  final bool? isSaved;
  final bool? isRated;
  final bool? isHidden;
  final bool? isInCustomList;
  final int? userRating;
  final String? comment;

  const UserGameActions({
    this.isSaved,
    this.isRated,
    this.isHidden,
    this.isInCustomList,
    this.userRating,
    this.comment,
  });

  factory UserGameActions.fromJson(Map<String, dynamic> json) {
    return UserGameActions(
      isSaved: json['saved'] as bool?,
      isRated: json['rating'] != null,
      isHidden: json['hid'] as bool?,
      isInCustomList: json['inCustomList'] as bool?,
      userRating: json['rating'] as int?,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saved': isSaved,
      'rating': userRating,
      'hid': isHidden,
      'inCustomList': isInCustomList,
      'comment': comment,
    };
  }

  UserGameActions copyWith({
    bool? isSaved,
    bool? isRated,
    bool? isHidden,
    bool? isInCustomList,
    int? userRating,
    String? comment,
  }) {
    return UserGameActions(
      isSaved: isSaved ?? this.isSaved,
      isRated: isRated ?? this.isRated,
      isHidden: isHidden ?? this.isHidden,
      isInCustomList: isInCustomList ?? this.isInCustomList,
      userRating: userRating ?? this.userRating,
      comment: comment ?? this.comment,
    );
  }

  @override
  String toString() {
    return 'UserGameActions(isSaved: $isSaved, isRated: $isRated, isHidden: $isHidden, isInCustomList: $isInCustomList, userRating: $userRating, comment: $comment)';
  }
} 