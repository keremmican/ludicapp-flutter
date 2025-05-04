enum CompletionStatus {
  notSelected,
  mainStory,
  mainStoryPlusExtras,
  hundredPercent;

  String toJson() {
    switch (this) {
      case CompletionStatus.notSelected:
        return 'NOT_SELECTED';
      case CompletionStatus.mainStory:
        return 'MAIN_STORY';
      case CompletionStatus.mainStoryPlusExtras:
        return 'MAIN_STORY_PLUS_EXTRAS';
      case CompletionStatus.hundredPercent:
        return 'HUNDRED_PERCENT';
    }
  }

  static CompletionStatus? fromJson(dynamic json) {
    if (json is String) {
      switch (json) {
        case 'NOT_SELECTED':
          return CompletionStatus.notSelected;
        case 'MAIN_STORY':
          return CompletionStatus.mainStory;
        case 'MAIN_STORY_PLUS_EXTRAS':
          return CompletionStatus.mainStoryPlusExtras;
        case 'HUNDRED_PERCENT':
          return CompletionStatus.hundredPercent;
        default:
          print('Unknown CompletionStatus string: $json');
          return null;
      }
    } else if (json != null) {
      print('Warning: Received non-String type for CompletionStatus: ${json.runtimeType}');
    }
    return null;
  }
} 