import 'package:ludicapp/core/enums/completion_status.dart';
import 'package:ludicapp/core/enums/play_status.dart';

class UserGameRating {
  final int id;
  final int userId;
  final int gameId;
  final int? rating;
  final String? comment;
  final PlayStatus? playStatus;
  final CompletionStatus? completionStatus;
  final int? playtimeInMinutes;
  final DateTime? lastUpdatedDate;

  UserGameRating({
    required this.id,
    required this.userId,
    required this.gameId,
    this.rating,
    this.comment,
    this.playStatus,
    this.completionStatus,
    this.playtimeInMinutes,
    this.lastUpdatedDate,
  });

  factory UserGameRating.fromJson(Map<String, dynamic> json) {
    // Helper function to parse the date, whether it's a String or List
    DateTime? parseLastUpdatedDate(dynamic dateValue) {
      if (dateValue == null) {
        return null;
      }
      if (dateValue is String) {
        // Handle standard ISO 8601 string
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print('Error parsing date string: $dateValue, error: $e');
          return null;
        }
      } else if (dateValue is List && dateValue.length >= 6) {
        // Handle the list format [year, month, day, hour, minute, second, nano?]
        try {
          // Ensure all parts are integers
          List<int> parts = dateValue.map((e) => e is int ? e : int.parse(e.toString())).toList();
          int year = parts[0];
          int month = parts[1];
          int day = parts[2];
          int hour = parts[3];
          int minute = parts[4];
          int second = parts[5];
          // Handle nanoseconds if present and convert to microseconds
          int microsecond = (parts.length > 6 && parts[6] != null) ? (parts[6] / 1000).round() : 0;
        
          // Construct DateTime (ensure it handles potential timezone issues if needed, assuming UTC for now)
          // Note: Dart's DateTime constructor uses local time by default unless specified.
          // If the backend sends UTC, use DateTime.utc(...)
           return DateTime(year, month, day, hour, minute, second, 0, microsecond);
           // If you know the backend sends local time components:
           // return DateTime(year, month, day, hour, minute, second, 0, microsecond);
        } catch (e) {
          print('Error parsing date list: $dateValue, error: $e');
          return null;
        }
      }
      print('Unrecognized date format for lastUpdatedDate: $dateValue');
      return null; // Return null if format is unrecognized
    }
    
    return UserGameRating(
      id: json['id'] as int? ?? 0, // Provide default if null
      userId: json['userId'] as int? ?? 0, // Provide default if null
      gameId: json['gameId'] as int? ?? 0, // Provide default if null
      rating: json['rating'] as int?,
      comment: json['comment'] as String?,
      playStatus: json['playStatus'] != null
          ? _parsePlayStatus(json['playStatus'])
          : null,
      completionStatus: json['completionStatus'] != null
          ? _parseCompletionStatus(json['completionStatus'])
          : null,
      playtimeInMinutes: json['playtimeInMinutes'] as int?,
      lastUpdatedDate: parseLastUpdatedDate(json['lastUpdatedDate']), // Use helper function
    );
  }

  // Daha güvenli PlayStatus parse etme metodu
  static PlayStatus _parsePlayStatus(dynamic value) {
    // Enum değerini doğrudan kullanarak dene
    if (value is String) {
      try {
        // İlk olarak PlayStatus.fromJson kullanarak dene
        PlayStatus? result = PlayStatus.fromJson(value);
        if (result != null) {
          return result;
        }
        
        // String değerini normalize et
        final normalized = value.replaceAll('_', '').toLowerCase();
        
        // Manuel olarak tüm enum değerleri kontrol et
        for (var status in PlayStatus.values) {
          if (status.name.toLowerCase() == normalized) {
            return status;
          }
        }
        
        // Basit stringler için kontrol
        switch(normalized) {
          case 'playing': return PlayStatus.playing;
          case 'completed': return PlayStatus.completed;
          case 'dropped': return PlayStatus.dropped;
          case 'onhold': return PlayStatus.onHold;
          case 'backlog': return PlayStatus.backlog;
          case 'skipped': return PlayStatus.skipped;
          case 'notset': return PlayStatus.notSet;
        }
      } catch (e) {
        // Hata durumunda sessizce devam et
      }
    }
    
    // Hata durumunda default değer döndür
    return PlayStatus.notSet;
  }
  
  // Daha güvenli CompletionStatus parse etme metodu
  static CompletionStatus _parseCompletionStatus(dynamic value) {
    // Enum değerini doğrudan kullanarak dene
    if (value is String) {
      try {
        // İlk olarak CompletionStatus.fromJson kullanarak dene
        CompletionStatus? result = CompletionStatus.fromJson(value);
        if (result != null) {
          return result;
        }
        
        // String değerini normalize et
        final normalized = value.replaceAll('_', '').toLowerCase();
        
        // Manuel olarak tüm enum değerleri kontrol et
        for (var status in CompletionStatus.values) {
          if (status.name.toLowerCase() == normalized) {
            return status;
          }
        }
        
        // Basit stringler için kontrol
        switch(normalized) {
          case 'mainstory': return CompletionStatus.mainStory;
          case 'mainstoryplusextras': return CompletionStatus.mainStoryPlusExtras;
          case 'hundredpercent': return CompletionStatus.hundredPercent;
          case 'notselected': return CompletionStatus.notSelected;
        }
      } catch (e) {
        // Hata durumunda sessizce devam et
      }
    }
    
    // Hata durumunda default değer döndür
    return CompletionStatus.notSelected;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'gameId': gameId,
      'rating': rating,
      'comment': comment,
      'playStatus': playStatus?.name,
      'completionStatus': completionStatus?.name,
      'playtimeInMinutes': playtimeInMinutes,
      'lastUpdatedDate': lastUpdatedDate?.toIso8601String(),
    };
  }
} 