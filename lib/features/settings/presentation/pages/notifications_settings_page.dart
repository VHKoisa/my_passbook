import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/models/models.dart';

class NotificationsSettingsPage extends ConsumerStatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  ConsumerState<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState
    extends ConsumerState<NotificationsSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Budget Alerts Section
          _buildSectionHeader(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Budget Alerts',
            iconColor: Colors.orange,
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Budget Alerts'),
                  subtitle: const Text(
                    'Get notified when you\'re close to exceeding your budget',
                  ),
                  value: settings.budgetAlerts,
                  onChanged: (value) => notifier.toggleBudgetAlerts(value),
                ),
                if (settings.budgetAlerts) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Alert Threshold'),
                    subtitle: Text(
                      'Notify when ${settings.budgetAlertThreshold}% of budget is spent',
                    ),
                    trailing: DropdownButton<int>(
                      value: settings.budgetAlertThreshold,
                      underline: const SizedBox(),
                      items: [50, 60, 70, 80, 90, 95].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text('$value%'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          notifier.updateBudgetAlertThreshold(value);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Daily Reminder Section
          _buildSectionHeader(
            icon: Icons.notifications_active_outlined,
            title: 'Daily Reminder',
            iconColor: Colors.blue,
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Daily Expense Reminder'),
                  subtitle: const Text(
                    'Remind me to log my daily expenses',
                  ),
                  value: settings.dailyReminder,
                  onChanged: (value) => notifier.toggleDailyReminder(value),
                ),
                if (settings.dailyReminder) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Reminder Time'),
                    subtitle: Text(
                      _formatTimeOfDay(settings.dailyReminderTime),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectDailyReminderTime(context, notifier),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Weekly Report Section
          _buildSectionHeader(
            icon: Icons.analytics_outlined,
            title: 'Weekly Summary',
            iconColor: Colors.purple,
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Weekly Spending Report'),
                  subtitle: const Text(
                    'Receive a summary of your weekly spending',
                  ),
                  value: settings.weeklyReport,
                  onChanged: (value) => notifier.toggleWeeklyReport(value),
                ),
                if (settings.weeklyReport) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Report Day'),
                    subtitle: Text(_getDayName(settings.weeklyReportDay)),
                    trailing: DropdownButton<int>(
                      value: settings.weeklyReportDay,
                      underline: const SizedBox(),
                      items: List.generate(7, (index) {
                        final day = index + 1;
                        return DropdownMenuItem(
                          value: day,
                          child: Text(_getDayName(day)),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          notifier.updateWeeklyReportDay(value);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bill Reminders Section
          _buildSectionHeader(
            icon: Icons.receipt_long_outlined,
            title: 'Bill Reminders',
            iconColor: Colors.green,
            action: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.primary,
              onPressed: () => _showAddBillDialog(context, notifier),
              tooltip: 'Add Bill Reminder',
            ),
          ),
          if (settings.billReminders.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No bill reminders',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add reminders for your recurring bills',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: settings.billReminders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final bill = entry.value;
                  return Column(
                    children: [
                      if (index > 0) const Divider(height: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              bill.isEnabled ? Colors.green[100] : Colors.grey[200],
                          child: Icon(
                            Icons.receipt_outlined,
                            color: bill.isEnabled ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(bill.name),
                        subtitle: Text(
                          '₹${bill.amount.toStringAsFixed(0)} • Day ${bill.dayOfMonth}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: bill.isEnabled,
                              onChanged: (value) {
                                notifier.updateBillReminder(
                                  bill.copyWith(isEnabled: value),
                                );
                              },
                            ),
                            PopupMenuButton<String>(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditBillDialog(context, notifier, bill);
                                } else if (value == 'delete') {
                                  _showDeleteBillDialog(
                                      context, notifier, bill);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 32),

          // Test Notification Button
          OutlinedButton.icon(
            onPressed: () => _testNotification(context),
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Send Test Notification'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color iconColor,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (action != null) action,
        ],
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getDayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[day - 1];
  }

  Future<void> _selectDailyReminderTime(
    BuildContext context,
    NotificationSettingsNotifier notifier,
  ) async {
    final settings = ref.read(notificationSettingsProvider);
    final time = await showTimePicker(
      context: context,
      initialTime: settings.dailyReminderTime,
    );
    if (time != null) {
      await notifier.updateDailyReminderTime(time);
    }
  }

  void _showAddBillDialog(
    BuildContext context,
    NotificationSettingsNotifier notifier,
  ) {
    _showBillDialog(context, notifier, null);
  }

  void _showEditBillDialog(
    BuildContext context,
    NotificationSettingsNotifier notifier,
    BillReminder bill,
  ) {
    _showBillDialog(context, notifier, bill);
  }

  void _showBillDialog(
    BuildContext context,
    NotificationSettingsNotifier notifier,
    BillReminder? existingBill,
  ) {
    final nameController = TextEditingController(text: existingBill?.name ?? '');
    final amountController = TextEditingController(
      text: existingBill?.amount.toStringAsFixed(0) ?? '',
    );
    int selectedDay = existingBill?.dayOfMonth ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingBill == null ? 'Add Bill Reminder' : 'Edit Bill Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Name',
                    hintText: 'e.g., Electricity, Rent, Netflix',
                    prefixIcon: Icon(Icons.receipt_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Enter amount',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due Day of Month'),
                  trailing: DropdownButton<int>(
                    value: selectedDay,
                    items: List.generate(28, (index) {
                      final day = index + 1;
                      return DropdownMenuItem(
                        value: day,
                        child: Text('Day $day'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedDay = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text) ?? 0;

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a bill name')),
                  );
                  return;
                }

                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                if (existingBill == null) {
                  notifier.addBillReminder(BillReminder(
                    id: const Uuid().v4(),
                    name: name,
                    amount: amount,
                    dayOfMonth: selectedDay,
                  ));
                } else {
                  notifier.updateBillReminder(existingBill.copyWith(
                    name: name,
                    amount: amount,
                    dayOfMonth: selectedDay,
                  ));
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      existingBill == null
                          ? 'Bill reminder added'
                          : 'Bill reminder updated',
                    ),
                  ),
                );
              },
              child: Text(existingBill == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteBillDialog(
    BuildContext context,
    NotificationSettingsNotifier notifier,
    BillReminder bill,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill Reminder'),
        content: Text(
          'Are you sure you want to delete the reminder for "${bill.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              notifier.deleteBillReminder(bill.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bill reminder deleted')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _testNotification(BuildContext context) async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.showNotification(
      id: 9999,
      title: '🎉 Test Notification',
      body: 'Notifications are working! You\'ll receive alerts as configured.',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
