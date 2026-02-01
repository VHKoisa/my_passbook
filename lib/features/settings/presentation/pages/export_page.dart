import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/export_service.dart';
import '../../../../shared/models/models.dart';

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;
  String _exportType = 'csv'; // 'csv' or 'pdf'

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Export Type Selection
            Text(
              'Export Format',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ExportTypeCard(
                    icon: Icons.table_chart_outlined,
                    title: 'CSV',
                    subtitle: 'Spreadsheet format',
                    isSelected: _exportType == 'csv',
                    onTap: () => setState(() => _exportType = 'csv'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ExportTypeCard(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'PDF',
                    subtitle: 'Report format',
                    isSelected: _exportType == 'pdf',
                    onTap: () => setState(() => _exportType = 'pdf'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Date Range Selection
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Quick Period Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PeriodChip(
                          label: 'This Month',
                          onTap: () => _setThisMonth(),
                        ),
                        _PeriodChip(
                          label: 'Last Month',
                          onTap: () => _setLastMonth(),
                        ),
                        _PeriodChip(
                          label: 'Last 3 Months',
                          onTap: () => _setLastNMonths(3),
                        ),
                        _PeriodChip(
                          label: 'Last 6 Months',
                          onTap: () => _setLastNMonths(6),
                        ),
                        _PeriodChip(
                          label: 'This Year',
                          onTap: () => _setThisYear(),
                        ),
                        _PeriodChip(
                          label: 'All Time',
                          onTap: () => _setAllTime(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Custom Date Range
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerButton(
                            label: 'From',
                            date: _startDate,
                            onTap: () => _selectDate(isStart: true),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward, color: Colors.grey),
                        ),
                        Expanded(
                          child: _DatePickerButton(
                            label: 'To',
                            date: _endDate,
                            onTap: () => _selectDate(isStart: false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Preview Info
            _PreviewCard(
              startDate: _startDate,
              endDate: _endDate,
              exportType: _exportType,
            ),

            const SizedBox(height: 24),

            // Export Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _export,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_exportType == 'csv'
                        ? Icons.download_outlined
                        : Icons.share_outlined),
                label: Text(_isExporting
                    ? 'Exporting...'
                    : _exportType == 'csv'
                        ? 'Export CSV'
                        : 'Generate & Share PDF'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Text
            Card(
              color: AppColors.info.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _exportType == 'csv'
                            ? 'CSV files can be opened in Excel, Google Sheets, or any spreadsheet application.'
                            : 'PDF reports include summary, category breakdown, and transaction list.',
                        style: TextStyle(
                          color: AppColors.info,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
    });
  }

  void _setLastMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month - 1, 1);
      _endDate = DateTime(now.year, now.month, 0);
    });
  }

  void _setLastNMonths(int months) {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month - months, now.day);
      _endDate = now;
    });
  }

  void _setThisYear() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, 1, 1);
      _endDate = now;
    });
  }

  void _setAllTime() {
    setState(() {
      _startDate = DateTime(2020, 1, 1);
      _endDate = DateTime.now();
    });
  }

  Future<void> _selectDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);

    try {
      final transactionsAsync = ref.read(transactionsProvider);
      final transactions = transactionsAsync.valueOrNull ?? [];
      
      // Filter by date range
      final filtered = transactions.where((t) =>
          !t.date.isBefore(_startDate) &&
          !t.date.isAfter(_endDate.add(const Duration(days: 1)))).toList();

      if (filtered.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No transactions found in selected period')),
          );
        }
        return;
      }

      final exportService = ref.read(exportServiceProvider);

      if (_exportType == 'csv') {
        final filePath = await exportService.exportTransactionsToCsv(filtered);
        await exportService.shareFile(
          filePath,
          subject: 'Transactions Export',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported ${filtered.length} transactions'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Calculate summary for the period
        double income = 0;
        double expense = 0;
        for (final t in filtered) {
          if (t.type == TransactionType.income) {
            income += t.amount;
          } else {
            expense += t.amount;
          }
        }
        final summary = {
          'income': income,
          'expense': expense,
          'balance': income - expense,
        };

        final user = ref.read(currentUserProvider);
        final pdfBytes = await exportService.generatePdfReport(
          transactions: filtered,
          summary: summary,
          startDate: _startDate,
          endDate: _endDate,
          userName: user?.displayName,
        );

        final fileName = 'financial_report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
        await exportService.sharePdf(pdfBytes, fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF report generated with ${filtered.length} transactions'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

class _ExportTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExportTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(date),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String exportType;

  const _PreviewCard({
    required this.startDate,
    required this.endDate,
    required this.exportType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: transactionsAsync.when(
          data: (transactions) {
            final filtered = transactions.where((t) =>
                !t.date.isBefore(startDate) &&
                !t.date.isAfter(endDate.add(const Duration(days: 1)))).toList();

            double income = 0;
            double expense = 0;
            for (final t in filtered) {
              if (t.type == TransactionType.income) {
                income += t.amount;
              } else {
                expense += t.amount;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Preview',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                _PreviewRow(
                  icon: Icons.receipt_long,
                  label: 'Transactions',
                  value: '${filtered.length}',
                ),
                const SizedBox(height: 8),
                _PreviewRow(
                  icon: Icons.arrow_upward,
                  label: 'Total Income',
                  value: '₹${income.toStringAsFixed(2)}',
                  color: AppColors.income,
                ),
                const SizedBox(height: 8),
                _PreviewRow(
                  icon: Icons.arrow_downward,
                  label: 'Total Expense',
                  value: '₹${expense.toStringAsFixed(2)}',
                  color: AppColors.expense,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Error loading data'),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
