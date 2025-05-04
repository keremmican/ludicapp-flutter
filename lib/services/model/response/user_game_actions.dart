import 'package:ludicapp/core/enums/completion_status.dart';
import 'package:ludicapp/core/enums/play_status.dart';

class UserGameActions {
  final bool? isSaved;
  final bool? isRated;
  final bool? isHidden;
  final bool? isInCustomList;
  final int? userRating;
  final String? comment;
  final PlayStatus? playStatus;
  final CompletionStatus? completionStatus;
  final int? playtimeInMinutes;

  const UserGameActions({
    this.isSaved,
    this.isRated,
    this.isHidden,
    this.isInCustomList,
    this.userRating,
    this.comment,
    this.playStatus,
    this.completionStatus,
    this.playtimeInMinutes,
  });

  factory UserGameActions.fromJson(Map<String, dynamic> json) {
    print('UserGameActions.fromJson called with: $json');
    
    bool? isSaved;
    bool? isHidden;
    bool? isInCustomList;
    int? rating;
    String? comment;
    PlayStatus? playStatus;
    CompletionStatus? completionStatus;
    int? playtimeInMinutes;
    
    try {
      // Güvenli bir şekilde bool değerleri alma
      if (json.containsKey('saved')) {
        isSaved = json['saved'] is bool ? json['saved'] : null;
      } else if (json.containsKey('isSaved')) {
        isSaved = json['isSaved'] is bool ? json['isSaved'] : null;
      }
      
      if (json.containsKey('hid')) {
        isHidden = json['hid'] is bool ? json['hid'] : null;
      } else if (json.containsKey('isHid')) {
        isHidden = json['isHid'] is bool ? json['isHid'] : null;
      }
      
      if (json.containsKey('inCustomList')) {
        isInCustomList = json['inCustomList'] is bool ? json['inCustomList'] : null;
      } else if (json.containsKey('isInCustomList')) {
        isInCustomList = json['isInCustomList'] is bool ? json['isInCustomList'] : null;
      }
      
      // Rating ve comment alma
      rating = json['rating'] is int ? json['rating'] : null;
      comment = json['comment'] is String ? json['comment'] : null;
      
      // playtimeInMinutes alma
      playtimeInMinutes = json['playtimeInMinutes'] is int ? json['playtimeInMinutes'] : null;
      
      // PlayStatus alma ve parse etme
      if (json.containsKey('playStatus') && json['playStatus'] != null) {
        dynamic rawPlayStatus = json['playStatus'];
        print('Raw playStatus: $rawPlayStatus (type: ${rawPlayStatus.runtimeType})');
        
        try {
          // Önce normal fromJson dene
          playStatus = PlayStatus.fromJson(rawPlayStatus);
          print('Normal parsing result for playStatus: $playStatus');
          
          // Eğer null dönerse manuel eşleşme dene
          if (playStatus == null && rawPlayStatus is String) {
            // Debug içine tam değeri koy 
            print('Trying manual parsing for PlayStatus. Original: \'$rawPlayStatus\'');
            // Tüm özel karakterleri ve boşlukları çıkar, büyük harfe çevir
            String normalized = rawPlayStatus.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
            print('Normalized playStatus: $normalized');
            
            switch (normalized) {
              case 'COMPLETED': 
                playStatus = PlayStatus.completed;
                break;
              case 'PLAYING':
                playStatus = PlayStatus.playing;
                break;
              case 'DROPPED':
                playStatus = PlayStatus.dropped;
                break;
              case 'ONHOLD':
                playStatus = PlayStatus.onHold;
                break;
              case 'BACKLOG':
                playStatus = PlayStatus.backlog;
                break;
              case 'SKIPPED':
                playStatus = PlayStatus.skipped;
                break;
              case 'NOTSET':
                playStatus = PlayStatus.notSet;
                break;
              default:
                print('No manual match found for PlayStatus: $normalized');
                playStatus = PlayStatus.notSet; // Default değer
            }
            print('Manual parsing result for playStatus: $playStatus');
          }
        } catch (e) {
          print('Error parsing playStatus: $e');
          playStatus = PlayStatus.notSet; // Default değer
        }
      } else {
        playStatus = PlayStatus.notSet; // Default değer
      }
      
      // CompletionStatus alma ve parse etme
      if (json.containsKey('completionStatus') && json['completionStatus'] != null) {
        dynamic rawCompletionStatus = json['completionStatus'];
        print('Raw completionStatus: $rawCompletionStatus (type: ${rawCompletionStatus.runtimeType})');
        
        try {
          // Önce normal fromJson dene
          completionStatus = CompletionStatus.fromJson(rawCompletionStatus);
          print('Normal parsing result for completionStatus: $completionStatus');
          
          // Eğer null dönerse manuel eşleşme dene
          if (completionStatus == null && rawCompletionStatus is String) {
            // Debug içine tam değeri koy
            print('Trying manual parsing for CompletionStatus. Original: \'$rawCompletionStatus\'');
            // Tüm özel karakterleri ve boşlukları çıkar, büyük harfe çevir
            String normalized = rawCompletionStatus.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
            print('Normalized completionStatus: $normalized');
            
            switch (normalized) {
              case 'MAINSTORY': 
                completionStatus = CompletionStatus.mainStory;
                break;
              case 'MAINSTORYPLUSEXTRAS':
                completionStatus = CompletionStatus.mainStoryPlusExtras;
                break;
              case 'HUNDREDPERCENT':
                completionStatus = CompletionStatus.hundredPercent;
                break;
              case 'NOTSELECTED':
                completionStatus = CompletionStatus.notSelected;
                break;
              default:
                print('No manual match found for CompletionStatus: $normalized');
                completionStatus = CompletionStatus.notSelected; // Default değer
            }
            print('Manual parsing result for completionStatus: $completionStatus');
          }
        } catch (e) {
          print('Error parsing completionStatus: $e');
          completionStatus = CompletionStatus.notSelected; // Default değer
        }
      } else {
        completionStatus = CompletionStatus.notSelected; // Default değer
      }
    } catch (e) {
      print('Error in UserGameActions.fromJson: $e');
      // Default değerler
      playStatus = PlayStatus.notSet;
      completionStatus = CompletionStatus.notSelected;
    }
    
    print('Final parsed values - playStatus: $playStatus, completionStatus: $completionStatus, playtimeInMinutes: $playtimeInMinutes');
    
    return UserGameActions(
      isSaved: isSaved,
      isRated: rating != null,
      isHidden: isHidden,
      isInCustomList: isInCustomList,
      userRating: rating,
      comment: comment,
      playStatus: playStatus,
      completionStatus: completionStatus,
      playtimeInMinutes: playtimeInMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSaved': isSaved,
      'rating': userRating,
      'isHid': isHidden,
      'isInCustomList': isInCustomList,
      'comment': comment,
      'playStatus': playStatus?.toJson(),
      'completionStatus': completionStatus?.toJson(),
      'playtimeInMinutes': playtimeInMinutes,
    };
  }

  UserGameActions copyWith({
    bool? isSaved,
    bool? isRated,
    bool? isHidden,
    bool? isInCustomList,
    int? userRating,
    String? comment,
    PlayStatus? playStatus,
    CompletionStatus? completionStatus,
    int? playtimeInMinutes,
  }) {
    return UserGameActions(
      isSaved: isSaved ?? this.isSaved,
      isRated: isRated ?? this.isRated,
      isHidden: isHidden ?? this.isHidden,
      isInCustomList: isInCustomList ?? this.isInCustomList,
      userRating: userRating ?? this.userRating,
      comment: comment ?? this.comment,
      playStatus: playStatus ?? this.playStatus,
      completionStatus: completionStatus ?? this.completionStatus,
      playtimeInMinutes: playtimeInMinutes ?? this.playtimeInMinutes,
    );
  }

  @override
  String toString() {
    return 'UserGameActions(isSaved: $isSaved, isRated: $isRated, isHidden: $isHidden, isInCustomList: $isInCustomList, userRating: $userRating, comment: $comment, playStatus: $playStatus, completionStatus: $completionStatus, playtimeInMinutes: $playtimeInMinutes)';
  }
} 