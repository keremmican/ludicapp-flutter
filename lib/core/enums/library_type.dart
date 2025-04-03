/// Represents the different types of user libraries.
enum LibraryType {
  /// The default "Saved" or "Wishlist" library.
  SAVED,
  
  /// Library for hidden games.
  HID, // Renamed from HIDDEN for consistency with Java
  
  /// Library for rated games.
  RATED,
  
  /// Library for games currently being played.
  CURRENTLY_PLAYING,

  /// A custom library created by the user.
  CUSTOM,

  /// Represents an unknown or unsupported library type.
  UNKNOWN;

  /// Parses a string to the corresponding LibraryType enum.
  /// 
  /// Defaults to UNKNOWN if the string doesn't match any known type.
  static LibraryType fromString(String? typeString) {
    if (typeString == null) return LibraryType.UNKNOWN;
    
    switch (typeString.toUpperCase()) {
      case 'SAVED':
        return LibraryType.SAVED;
      case 'HID': // Use HID as per Java enum
        return LibraryType.HID;
      case 'RATED':
        return LibraryType.RATED;
      case 'CURRENTLY_PLAYING':
        return LibraryType.CURRENTLY_PLAYING;
      case 'CUSTOM':
        return LibraryType.CUSTOM;
      default:
        print('Warning: Unknown LibraryType string received: $typeString');
        return LibraryType.UNKNOWN;
    }
  }

  /// Converts the enum to its string representation (uppercase).
  String toJsonString() {
    return name; // .name returns the enum identifier as a string (e.g., "CUSTOM")
  }
} 