enum PlayStatus {
  notSet,
  playing,
  completed,
  dropped,
  onHold,
  backlog,
  skipped;

  String toJson() {
    switch (this) {
      case PlayStatus.notSet:
        return 'NOT_SET';
      case PlayStatus.playing:
        return 'PLAYING';
      case PlayStatus.completed:
        return 'COMPLETED';
      case PlayStatus.dropped:
        return 'DROPPED';
      case PlayStatus.onHold:
        return 'ON_HOLD';
      case PlayStatus.backlog:
        return 'BACKLOG';
      case PlayStatus.skipped:
        return 'SKIPPED';
    }
  }

  static PlayStatus? fromJson(dynamic json) {
    if (json is String) {
      switch (json) {
        case 'NOT_SET':
          return PlayStatus.notSet;
        case 'PLAYING':
          return PlayStatus.playing;
        case 'COMPLETED':
          return PlayStatus.completed;
        case 'DROPPED':
          return PlayStatus.dropped;
        case 'ON_HOLD':
          return PlayStatus.onHold;
        case 'BACKLOG':
          return PlayStatus.backlog;
        case 'SKIPPED':
          return PlayStatus.skipped;
        default:
          print('Unknown PlayStatus string: $json');
          return null;
      }
    } else if (json != null) {
      print('Warning: Received non-String type for PlayStatus: ${json.runtimeType}');
    }
    return null;
  }
} 