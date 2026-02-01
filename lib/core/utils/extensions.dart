import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// String Extensions
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get initials {
    if (isEmpty) return '';
    final words = trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 2)).toUpperCase();
    }
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
}

// DateTime Extensions
extension DateTimeExtension on DateTime {
  String get formatted => DateFormat('MMM dd, yyyy').format(this);
  
  String get formattedWithTime => DateFormat('MMM dd, yyyy HH:mm').format(this);
  
  String get dayMonth => DateFormat('dd MMM').format(this);
  
  String get monthYear => DateFormat('MMMM yyyy').format(this);
  
  String get time => DateFormat('HH:mm').format(this);
  
  String get dayName => DateFormat('EEEE').format(this);
  
  String get shortDayName => DateFormat('EEE').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
           isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  bool get isThisYear {
    return year == DateTime.now().year;
  }

  DateTime get startOfDay => DateTime(year, month, day);
  
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
  
  DateTime get startOfMonth => DateTime(year, month, 1);
  
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);

  String get relativeDate {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isThisWeek) return dayName;
    if (isThisYear) return dayMonth;
    return formatted;
  }
}

// Number Extensions
extension NumberExtension on num {
  String get currency => NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
  ).format(this);

  String get compactCurrency {
    if (this >= 10000000) {
      return '₹${(this / 10000000).toStringAsFixed(1)}Cr';
    } else if (this >= 100000) {
      return '₹${(this / 100000).toStringAsFixed(1)}L';
    } else if (this >= 1000) {
      return '₹${(this / 1000).toStringAsFixed(1)}K';
    }
    return currency;
  }

  String get percentage => '${toStringAsFixed(1)}%';
}

// Context Extensions
extension ContextExtension on BuildContext {
  // Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  // Media Query
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  
  // Responsive
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  // Snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Navigation
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
}

// List Extensions
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}
