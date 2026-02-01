class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'My Passbook';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  static const String categoriesCollection = 'categories';
  static const String budgetsCollection = 'budgets';
  static const String personsCollection = 'persons';
  static const String settlementsCollection = 'settlements';

  // Hive Boxes
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';
  static const String transactionsBox = 'transactions_cache';

  // Default Values
  static const String defaultCurrency = 'INR';
  static const String defaultCurrencySymbol = '₹';

  // Pagination
  static const int defaultPageSize = 20;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
