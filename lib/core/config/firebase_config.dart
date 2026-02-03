/// Firebase configuration loaded from environment
/// This file contains the structure - actual keys are loaded from .env file
class FirebaseConfig {
  // Android
  static String get androidApiKey => 
      const String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: '');
  static String get androidAppId => 
      const String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '');

  // iOS
  static String get iosApiKey => 
      const String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: '');
  static String get iosAppId => 
      const String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: '');

  // Web
  static String get webApiKey => 
      const String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: '');
  static String get webAppId => 
      const String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: '');
  static String get webAuthDomain => 
      const String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN', defaultValue: '');
  static String get webMeasurementId => 
      const String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID', defaultValue: '');

  // Common
  static String get projectId => 
      const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static String get storageBucket => 
      const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
  static String get messagingSenderId => 
      const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
}
