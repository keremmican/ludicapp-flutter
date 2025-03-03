class UserGameActions {
  final bool? isSaved;
  final bool? isRated;
  final bool? isHidden;
  final int? userRating;

  const UserGameActions({
    this.isSaved,
    this.isRated,
    this.isHidden,
    this.userRating,
  });

  factory UserGameActions.fromJson(Map<String, dynamic> json) {
    return UserGameActions(
      isSaved: json['saved'] as bool?,
      isRated: json['rating'] != null,
      isHidden: json['hid'] as bool?,
      userRating: json['rating'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saved': isSaved,
      'rating': userRating,
      'hid': isHidden,
    };
  }

  UserGameActions copyWith({
    bool? isSaved,
    bool? isRated,
    bool? isHidden,
    int? userRating,
  }) {
    return UserGameActions(
      isSaved: isSaved ?? this.isSaved,
      isRated: isRated ?? this.isRated,
      isHidden: isHidden ?? this.isHidden,
      userRating: userRating ?? this.userRating,
    );
  }

  @override
  String toString() {
    return 'UserGameActions(isSaved: $isSaved, isRated: $isRated, isHidden: $isHidden, userRating: $userRating)';
  }
} 