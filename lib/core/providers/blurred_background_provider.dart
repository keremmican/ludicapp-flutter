import 'package:flutter/material.dart';

class BlurredBackgroundProvider {
  static final BlurredBackgroundProvider _instance = BlurredBackgroundProvider._internal();
  final Map<String, ImageProvider> _cache = {};

  factory BlurredBackgroundProvider() {
    return _instance;
  }

  BlurredBackgroundProvider._internal();

  void cacheBackground(String key, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    
    if (!_cache.containsKey(key)) {
      _cache[key] = NetworkImage(imageUrl);
    }
  }

  ImageProvider? getBackground(String key) {
    return _cache[key];
  }

  void clearCache() {
    _cache.clear();
  }
} 