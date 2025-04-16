class ApiConstants {
  static const String baseUrl = 'https://collectionapi.metmuseum.org/public/collection/v1';
  
  // API endpoints
  static const String search = '/search';
  static const String objects = '/objects';
  
  // Feature flags
  static const bool enableAR = true;
  static const bool enableImageRecognition = true;
}

class AppConstants {
  static const String appName = 'Met Museum Explorer';
  static const String appVersion = '1.0.0';
  
  // Cache durations
  static const int artworkCacheDurationDays = 1;
  static const int recognitionCacheDurationDays = 7;
  
  // Image processing
  static const int maxImageSize = 1024; // pixels
  static const double minConfidenceThreshold = 0.6;
  
  // UI constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultIconSize = 24.0;
}

class UIConstants {
  // Colors
  static const int primaryColorValue = 0xFF3F51B5;
  static const int accentColorValue = 0xFFFF4081;
  
  // Dimensions
  static const double defaultPadding = 16.0;
  static const double cardElevation = 4.0;
  static const double borderRadius = 8.0;
  
  // Animation durations
  static const int shortAnimationDuration = 200; // milliseconds
  static const int mediumAnimationDuration = 350; // milliseconds
} 