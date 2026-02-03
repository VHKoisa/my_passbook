import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../../shared/models/models.dart';

/// Notification service for handling local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  NotificationSettingsModel _settings = const NotificationSettingsModel();

  static const String _settingsKey = 'notification_settings';
  static const String _channelId = 'my_passbook_notifications';
  static const String _channelName = 'My Passbook Notifications';
  static const String _channelDescription = 'Notifications for expense tracking';

  // Notification IDs
  static const int _dailyReminderId = 1000;
  static const int _weeklyReportId = 1001;
  static const int _budgetAlertBaseId = 2000;
  static const int _billReminderBaseId = 3000;

  NotificationSettingsModel get settings => _settings;

  /// Initialize the notification service
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize notifications (skip on web)
    if (!kIsWeb) {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // We'll request manually
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        );
        await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
        
        // Request notification permission for Android 13+ (API 33+)
        await requestPermissions();
      }
      
      // Request iOS permissions
      if (Platform.isIOS) {
        await requestPermissions();
      }
    }

    // Load saved settings
    await _loadSettings();

    _isInitialized = true;

    // Schedule notifications based on settings
    await _scheduleAllNotifications();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on notification payload
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Load notification settings from storage
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        _settings = NotificationSettingsModel.fromJson(
          json.decode(settingsJson) as Map<String, dynamic>,
        );
      } catch (e) {
        debugPrint('Error loading notification settings: $e');
      }
    }
  }

  /// Save notification settings to storage
  Future<void> saveSettings(NotificationSettingsModel settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings.toJson()));
    await _scheduleAllNotifications();
  }

  /// Schedule all notifications based on current settings
  Future<void> _scheduleAllNotifications() async {
    if (kIsWeb) return;

    // Cancel all existing scheduled notifications
    await _notifications.cancelAll();

    // Schedule daily reminder
    if (_settings.dailyReminder) {
      await _scheduleDailyReminder();
    }

    // Schedule weekly report
    if (_settings.weeklyReport) {
      await _scheduleWeeklyReport();
    }

    // Schedule bill reminders
    for (final bill in _settings.billReminders) {
      if (bill.isEnabled) {
        await _scheduleBillReminder(bill);
      }
    }
  }

  /// Schedule daily reminder notification
  Future<void> _scheduleDailyReminder() async {
    if (kIsWeb) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _settings.dailyReminderTime.hour,
      _settings.dailyReminderTime.minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _dailyReminderId,
      '💰 Daily Expense Reminder',
      'Don\'t forget to log your expenses for today!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  /// Schedule weekly report notification
  Future<void> _scheduleWeeklyReport() async {
    if (kIsWeb) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9, // 9 AM
      0,
    );

    // Find next occurrence of the selected day
    while (scheduledDate.weekday != _settings.weeklyReportDay ||
        scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _weeklyReportId,
      '📊 Weekly Expense Report',
      'Your weekly spending summary is ready. Tap to view!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_report',
    );
  }

  /// Schedule bill reminder notification
  Future<void> _scheduleBillReminder(BillReminder bill) async {
    if (kIsWeb) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      bill.dayOfMonth.clamp(1, 28), // Clamp to avoid invalid dates
      9, // 9 AM
      0,
    );

    // If the day has passed this month, schedule for next month
    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        bill.dayOfMonth.clamp(1, 28),
        9,
        0,
      );
    }

    final notificationId = _billReminderBaseId + bill.id.hashCode.abs() % 1000;

    await _notifications.zonedSchedule(
      notificationId,
      '📅 Bill Reminder: ${bill.name}',
      'Your ${bill.name} bill of ₹${bill.amount.toStringAsFixed(2)} is due today!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      payload: 'bill_reminder:${bill.id}',
    );
  }

  /// Show immediate budget alert notification
  Future<void> showBudgetAlert({
    required String categoryName,
    required double spent,
    required double budget,
    required int percentage,
  }) async {
    if (kIsWeb || !_settings.budgetAlerts) return;

    final notificationId =
        _budgetAlertBaseId + categoryName.hashCode.abs() % 1000;

    String title;
    String body;

    if (percentage >= 100) {
      title = '🚨 Budget Exceeded!';
      body =
          'You\'ve exceeded your $categoryName budget! Spent: ₹${spent.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}';
    } else {
      title = '⚠️ Budget Warning';
      body =
          'You\'ve used $percentage% of your $categoryName budget. ₹${(budget - spent).toStringAsFixed(0)} remaining.';
    }

    await _notifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: percentage >= 100 ? Colors.red : Colors.orange,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'budget_alert:$categoryName',
    );
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb) return [];
    return await _notifications.pendingNotificationRequests();
  }

  /// Add a bill reminder
  Future<void> addBillReminder(BillReminder bill) async {
    final updatedReminders = List<BillReminder>.from(_settings.billReminders)
      ..add(bill);
    await saveSettings(_settings.copyWith(billReminders: updatedReminders));
  }

  /// Update a bill reminder
  Future<void> updateBillReminder(BillReminder bill) async {
    final updatedReminders = _settings.billReminders.map((b) {
      return b.id == bill.id ? bill : b;
    }).toList();
    await saveSettings(_settings.copyWith(billReminders: updatedReminders));
  }

  /// Delete a bill reminder
  Future<void> deleteBillReminder(String billId) async {
    final updatedReminders =
        _settings.billReminders.where((b) => b.id != billId).toList();
    await saveSettings(_settings.copyWith(billReminders: updatedReminders));
  }

  /// Toggle daily reminder
  Future<void> toggleDailyReminder(bool enabled) async {
    await saveSettings(_settings.copyWith(dailyReminder: enabled));
  }

  /// Update daily reminder time
  Future<void> updateDailyReminderTime(TimeOfDay time) async {
    await saveSettings(_settings.copyWith(dailyReminderTime: time));
  }

  /// Toggle budget alerts
  Future<void> toggleBudgetAlerts(bool enabled) async {
    await saveSettings(_settings.copyWith(budgetAlerts: enabled));
  }

  /// Update budget alert threshold
  Future<void> updateBudgetAlertThreshold(int threshold) async {
    await saveSettings(_settings.copyWith(budgetAlertThreshold: threshold));
  }

  /// Toggle weekly report
  Future<void> toggleWeeklyReport(bool enabled) async {
    await saveSettings(_settings.copyWith(weeklyReport: enabled));
  }

  /// Update weekly report day
  Future<void> updateWeeklyReportDay(int day) async {
    await saveSettings(_settings.copyWith(weeklyReportDay: day));
  }
}

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for notification settings
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettingsModel>(
  (ref) => NotificationSettingsNotifier(ref.watch(notificationServiceProvider)),
);

/// Notifier for notification settings
class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsModel> {
  final NotificationService _service;

  NotificationSettingsNotifier(this._service)
      : super(_service.settings);

  void refresh() {
    state = _service.settings;
  }

  Future<void> toggleBudgetAlerts(bool enabled) async {
    await _service.toggleBudgetAlerts(enabled);
    state = _service.settings;
  }

  Future<void> updateBudgetAlertThreshold(int threshold) async {
    await _service.updateBudgetAlertThreshold(threshold);
    state = _service.settings;
  }

  Future<void> toggleDailyReminder(bool enabled) async {
    await _service.toggleDailyReminder(enabled);
    state = _service.settings;
  }

  Future<void> updateDailyReminderTime(TimeOfDay time) async {
    await _service.updateDailyReminderTime(time);
    state = _service.settings;
  }

  Future<void> toggleWeeklyReport(bool enabled) async {
    await _service.toggleWeeklyReport(enabled);
    state = _service.settings;
  }

  Future<void> updateWeeklyReportDay(int day) async {
    await _service.updateWeeklyReportDay(day);
    state = _service.settings;
  }

  Future<void> addBillReminder(BillReminder bill) async {
    await _service.addBillReminder(bill);
    state = _service.settings;
  }

  Future<void> updateBillReminder(BillReminder bill) async {
    await _service.updateBillReminder(bill);
    state = _service.settings;
  }

  Future<void> deleteBillReminder(String billId) async {
    await _service.deleteBillReminder(billId);
    state = _service.settings;
  }
}
