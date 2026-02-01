import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Model for user notification settings
class NotificationSettingsModel extends Equatable {
  final bool budgetAlerts;
  final int budgetAlertThreshold; // Percentage (e.g., 80 means alert at 80% spent)
  final bool dailyReminder;
  final TimeOfDay dailyReminderTime;
  final bool weeklyReport;
  final int weeklyReportDay; // 1 = Monday, 7 = Sunday
  final List<BillReminder> billReminders;

  const NotificationSettingsModel({
    this.budgetAlerts = true,
    this.budgetAlertThreshold = 80,
    this.dailyReminder = false,
    this.dailyReminderTime = const TimeOfDay(hour: 20, minute: 0),
    this.weeklyReport = false,
    this.weeklyReportDay = 1,
    this.billReminders = const [],
  });

  NotificationSettingsModel copyWith({
    bool? budgetAlerts,
    int? budgetAlertThreshold,
    bool? dailyReminder,
    TimeOfDay? dailyReminderTime,
    bool? weeklyReport,
    int? weeklyReportDay,
    List<BillReminder>? billReminders,
  }) {
    return NotificationSettingsModel(
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      weeklyReport: weeklyReport ?? this.weeklyReport,
      weeklyReportDay: weeklyReportDay ?? this.weeklyReportDay,
      billReminders: billReminders ?? this.billReminders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budgetAlerts': budgetAlerts,
      'budgetAlertThreshold': budgetAlertThreshold,
      'dailyReminder': dailyReminder,
      'dailyReminderTimeHour': dailyReminderTime.hour,
      'dailyReminderTimeMinute': dailyReminderTime.minute,
      'weeklyReport': weeklyReport,
      'weeklyReportDay': weeklyReportDay,
      'billReminders': billReminders.map((b) => b.toJson()).toList(),
    };
  }

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      budgetAlerts: json['budgetAlerts'] ?? true,
      budgetAlertThreshold: json['budgetAlertThreshold'] ?? 80,
      dailyReminder: json['dailyReminder'] ?? false,
      dailyReminderTime: TimeOfDay(
        hour: json['dailyReminderTimeHour'] ?? 20,
        minute: json['dailyReminderTimeMinute'] ?? 0,
      ),
      weeklyReport: json['weeklyReport'] ?? false,
      weeklyReportDay: json['weeklyReportDay'] ?? 1,
      billReminders: (json['billReminders'] as List<dynamic>?)
              ?.map((b) => BillReminder.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        budgetAlerts,
        budgetAlertThreshold,
        dailyReminder,
        dailyReminderTime,
        weeklyReport,
        weeklyReportDay,
        billReminders,
      ];
}

/// Model for bill reminder
class BillReminder extends Equatable {
  final String id;
  final String name;
  final double amount;
  final int dayOfMonth; // 1-31
  final bool isEnabled;
  final DateTime? lastNotified;

  const BillReminder({
    required this.id,
    required this.name,
    required this.amount,
    required this.dayOfMonth,
    this.isEnabled = true,
    this.lastNotified,
  });

  BillReminder copyWith({
    String? id,
    String? name,
    double? amount,
    int? dayOfMonth,
    bool? isEnabled,
    DateTime? lastNotified,
  }) {
    return BillReminder(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isEnabled: isEnabled ?? this.isEnabled,
      lastNotified: lastNotified ?? this.lastNotified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'dayOfMonth': dayOfMonth,
      'isEnabled': isEnabled,
      'lastNotified': lastNotified?.toIso8601String(),
    };
  }

  factory BillReminder.fromJson(Map<String, dynamic> json) {
    return BillReminder(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      dayOfMonth: json['dayOfMonth'] ?? 1,
      isEnabled: json['isEnabled'] ?? true,
      lastNotified: json['lastNotified'] != null
          ? DateTime.parse(json['lastNotified'])
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, amount, dayOfMonth, isEnabled, lastNotified];
}
