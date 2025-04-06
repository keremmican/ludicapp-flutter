enum ProfilePhotoType {
  DEFAULT_1,
  DEFAULT_2,
  DEFAULT_3,
  DEFAULT_4,
  CUSTOM;

  // Helper to get asset path
  String? get assetPath {
    if (this == CUSTOM) return null;
    
    // In Flutter, assets in pubspec.yaml can be defined with 'lib/' prefix,
    // but when loading them with Image.asset(), you can use either format depending on setup.
    // Be consistent with the rest of the app.
    return 'lib/assets/images/profile/$name.png'; 
  }

  // Helper for fromJson, add error handling as needed
  static ProfilePhotoType fromString(String? typeString) {
    if (typeString == null) return ProfilePhotoType.DEFAULT_1; // Default fallback
    return ProfilePhotoType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => ProfilePhotoType.DEFAULT_1, // Fallback for unknown types
    );
  }
} 