class UserGameRatingWithUser {
  final int id;
  final int userId;
  final String username;
  final String? profilePhotoUrl;
  final String? profilePhotoType;
  final int gameId;
  final int rating;
  final String? comment;
  final DateTime ratingDate;

  UserGameRatingWithUser({
    required this.id,
    required this.userId,
    required this.username,
    this.profilePhotoUrl,
    this.profilePhotoType,
    required this.gameId,
    required this.rating,
    this.comment,
    required this.ratingDate,
  });

  factory UserGameRatingWithUser.fromJson(Map<String, dynamic> json) {
    // ratingDate bir liste veya String olarak gelebilir
    DateTime parsedDate;
    
    if (json['ratingDate'] is List) {
      // Liste formatı: [yıl, ay, gün, saat, dakika, saniye, nanosaniye]
      final List<dynamic> dateList = json['ratingDate'] as List;
      final year = dateList[0] as int;
      final month = dateList[1] as int;
      final day = dateList[2] as int;
      
      if (dateList.length > 3) {
        final hour = dateList[3] as int;
        final minute = dateList.length > 4 ? dateList[4] as int : 0;
        final second = dateList.length > 5 ? dateList[5] as int : 0;
        
        // Nanosaniye'yi mikrosaniye'ye çevir (varsa)
        final microsecond = dateList.length > 6 ? (dateList[6] as int) ~/ 1000 : 0;
        
        parsedDate = DateTime(year, month, day, hour, minute, second, microsecond);
      } else {
        parsedDate = DateTime(year, month, day);
      }
    } else if (json['ratingDate'] is String) {
      // String format: ISO8601
      parsedDate = DateTime.parse(json['ratingDate'] as String);
    } else {
      // Fallback to current date if format is unknown
      print('Unknown ratingDate format: ${json['ratingDate']}');
      parsedDate = DateTime.now();
    }
    
    return UserGameRatingWithUser(
      id: json['id'] as int,
      userId: json['userId'] as int,
      username: json['username'] as String,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      profilePhotoType: json['profilePhotoType'] as String?,
      gameId: json['gameId'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      ratingDate: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'profilePhotoUrl': profilePhotoUrl,
      'profilePhotoType': profilePhotoType,
      'gameId': gameId,
      'rating': rating,
      'comment': comment,
      'ratingDate': ratingDate.toIso8601String(),
    };
  }
} 