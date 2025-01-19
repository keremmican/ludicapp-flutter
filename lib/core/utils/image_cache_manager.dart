import 'package:flutter/material.dart';

class ImageCacheManager {
  static final Map<String, ImageProvider> _blurredBackgrounds = {};

  static void cacheBlurredBackground(String gameId, String imageUrl) {
    if (!_blurredBackgrounds.containsKey(gameId)) {
      final networkImage = NetworkImage(imageUrl);
      _blurredBackgrounds[gameId] = networkImage;
    }
  }

  static ImageProvider? getBlurredBackground(String gameId) {
    return _blurredBackgrounds[gameId];
  }

  static void clearCache() {
    _blurredBackgrounds.clear();
  }
} 