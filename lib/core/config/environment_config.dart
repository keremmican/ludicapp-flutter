class EnvironmentConfig {
  static const bool isDevelopment = bool.fromEnvironment('DEV_MODE', defaultValue: true);
  
  static String get baseUrl {
    if (isDevelopment) {
      return "http://10.0.2.2:8081/"; // Development URL (Android Emulator localhost)
    } else {
      return "http://77.37.87.128:8081/"; // Production URL
    }
  }
} 