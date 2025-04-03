import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Kalıcılık için import eklendi

// Tema modunu saklamak için kullanılacak anahtar
const String _themePrefsKey = 'selectedThemeMode';

// ThemeMode enum'ını string'e ve string'den ThemeMode'a dönüştürmek için yardımcı fonksiyonlar
String _themeModeToString(ThemeMode themeMode) => themeMode.toString().split('.').last;
ThemeMode _stringToThemeMode(String themeString) =>
    ThemeMode.values.firstWhere((e) => _themeModeToString(e) == themeString, orElse: () => ThemeMode.dark);


// StateNotifier'ı tanımlıyoruz
class ThemeNotifier extends StateNotifier<ThemeMode> {
  // Başlangıç değeri ThemeMode.dark, ama kaydedilmiş tercihi yükleyeceğiz
  ThemeNotifier() : super(ThemeMode.dark) { 
    _loadThemeMode(); // Kaydedilmiş temayı yükle
  }

  // Tema modunu değiştiren ve kaydeden fonksiyon
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (state != themeMode) {
      state = themeMode;
      _saveThemeMode(themeMode); // Yeni temayı kaydet
    }
  }

  // Kalıcılık için metodlar 
  Future<void> _loadThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String savedTheme = prefs.getString(_themePrefsKey) ?? _themeModeToString(ThemeMode.dark); // Default'u dark yap
    state = _stringToThemeMode(savedTheme);
  }

  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefsKey, _themeModeToString(themeMode));
  }
}

// StateNotifierProvider'ı oluşturuyoruz
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});