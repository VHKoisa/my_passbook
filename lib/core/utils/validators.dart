import '../constants/app_strings.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    if (value.length < 6) {
      return AppStrings.invalidPassword;
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    if (value != password) {
      return AppStrings.passwordMismatch;
    }
    return null;
  }

  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return AppStrings.invalidAmount;
    }
    return null;
  }

  static String? minLength(String? value, int minLength) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    if (value.length < minLength) {
      return 'Must be at least $minLength characters';
    }
    return null;
  }

  static String? maxLength(String? value, int maxLength) {
    if (value != null && value.length > maxLength) {
      return 'Must be at most $maxLength characters';
    }
    return null;
  }
}
