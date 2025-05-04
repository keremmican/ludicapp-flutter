import 'package:ludicapp/core/enums/completion_status.dart';
import 'package:ludicapp/core/enums/play_status.dart';
import 'package:ludicapp/core/enums/profile_photo_type.dart'; // Assuming ProfilePhotoType enum exists

class UserGameRatingWithUser {
  final int id;
  final int userId;
  final String username;
  final String? profilePhotoUrl;
  final String? profilePhotoType;
  final int gameId;
  final int? rating;
  final String? comment;
  final PlayStatus? playStatus;
  final CompletionStatus? completionStatus;
  final int? playtimeInMinutes;
  final DateTime? lastUpdatedDate;

  UserGameRatingWithUser({
    required this.id,
    required this.userId,
    required this.username,
    this.profilePhotoUrl,
    this.profilePhotoType,
    required this.gameId,
    this.rating,
    this.comment,
    this.playStatus,
    this.completionStatus,
    this.playtimeInMinutes,
    this.lastUpdatedDate,
  });

  factory UserGameRatingWithUser.fromJson(Map<String, dynamic> json) {
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
          print('Error parsing date string in UserGameRatingWithUser: $dateValue, error: $e');
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
          
          // Construct DateTime (assuming local time components based on typical Java serialization)
          return DateTime(year, month, day, hour, minute, second, 0, microsecond);
        } catch (e) {
          print('Error parsing date list in UserGameRatingWithUser: $dateValue, error: $e');
          return null;
        }
      }
      print('Unrecognized date format for lastUpdatedDate in UserGameRatingWithUser: $dateValue');
      return null; // Return null if format is unrecognized
    }
    
    // Parse PlayStatus properly using the fromJson method
    PlayStatus? parsePlayStatus(dynamic playStatusValue) {
      if (playStatusValue == null) {
        return PlayStatus.notSet; // Default value
      }
      
      // Use the fromJson method from PlayStatus enum
      PlayStatus? status = PlayStatus.fromJson(playStatusValue);
      if (status != null) {
        return status;
      }
      
      // If still null, try string conversion for backward compatibility
      if (playStatusValue is String) {
        try {
          // Try to match enum by name (case insensitive)
          String normalized = playStatusValue.replaceAll('_', '').toLowerCase();
          for (var value in PlayStatus.values) {
            if (value.name.toLowerCase() == normalized) {
              return value;
            }
          }
          
          // Manual mapping as fallback
          switch (playStatusValue.toUpperCase()) {
            case 'COMPLETED': return PlayStatus.completed;
            case 'PLAYING': return PlayStatus.playing;
            case 'DROPPED': return PlayStatus.dropped;
            case 'ON_HOLD': return PlayStatus.onHold;
            case 'BACKLOG': return PlayStatus.backlog;
            case 'SKIPPED': return PlayStatus.skipped;
            case 'NOT_SET': return PlayStatus.notSet;
            default: 
              print('Unknown PlayStatus value: $playStatusValue');
              return PlayStatus.notSet;
          }
        } catch (e) {
          print('Error parsing PlayStatus: $e');
          return PlayStatus.notSet;
        }
      }
      
      print('Could not parse PlayStatus from: $playStatusValue');
      return PlayStatus.notSet;
    }
    
    // Parse CompletionStatus properly using the fromJson method
    CompletionStatus? parseCompletionStatus(dynamic completionStatusValue) {
      if (completionStatusValue == null) {
        return CompletionStatus.notSelected; // Default value
      }
      
      // Use the fromJson method from CompletionStatus enum
      CompletionStatus? status = CompletionStatus.fromJson(completionStatusValue);
      if (status != null) {
        return status;
      }
      
      // If still null, try string conversion for backward compatibility
      if (completionStatusValue is String) {
        try {
          // Try to match enum by name (case insensitive)
          String normalized = completionStatusValue.replaceAll('_', '').toLowerCase();
          for (var value in CompletionStatus.values) {
            if (value.name.toLowerCase() == normalized) {
              return value;
            }
          }
          
          // Manual mapping as fallback
          switch (completionStatusValue.toUpperCase()) {
            case 'MAIN_STORY': return CompletionStatus.mainStory;
            case 'MAIN_STORY_PLUS_EXTRAS': return CompletionStatus.mainStoryPlusExtras;
            case 'HUNDRED_PERCENT': return CompletionStatus.hundredPercent;
            case 'NOT_SELECTED': return CompletionStatus.notSelected;
            default:
              print('Unknown CompletionStatus value: $completionStatusValue');
              return CompletionStatus.notSelected;
          }
        } catch (e) {
          print('Error parsing CompletionStatus: $e');
          return CompletionStatus.notSelected;
        }
      }
      
      print('Could not parse CompletionStatus from: $completionStatusValue');
      return CompletionStatus.notSelected;
    }
    
    return UserGameRatingWithUser(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      username: json['username'] as String? ?? 'Unknown User',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      profilePhotoType: json['profilePhotoType'] as String?, // Keep as String
      gameId: json['gameId'] as int? ?? 0,
      rating: json['rating'] as int?,
      comment: json['comment'] as String?,
      playStatus: parsePlayStatus(json['playStatus']),
      completionStatus: parseCompletionStatus(json['completionStatus']),
      playtimeInMinutes: json['playtimeInMinutes'] as int?,
      lastUpdatedDate: parseLastUpdatedDate(json['lastUpdatedDate']), // Use helper
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
      'playStatus': playStatus?.toJson(),
      'completionStatus': completionStatus?.toJson(),
      'playtimeInMinutes': playtimeInMinutes,
      'lastUpdatedDate': lastUpdatedDate?.toIso8601String(),
    };
  }
} 