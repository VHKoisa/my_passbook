import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/models/models.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show budget history
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(budgetsProvider);
          ref.invalidate(monthlySummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Budget Card
              _OverallBudgetCard(
                budgetsAsync: budgetsAsync,
                summaryAsync: summaryAsync,
              ),
              const SizedBox(height: 24),

              // Category Budgets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category Budgets',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddCategoryBudgetSheet(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CategoryBudgetsList(budgetsAsync: budgetsAsync),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBudgetSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Set Budget'),
      ),
    );
  }

  void _showCreateBudgetSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateBudgetSheet(
        onSave: (amount) async {
          final user = ref.read(currentUserProvider);
          if (user == null) return;

          final now = DateTime.now();
          final budget = BudgetModel.monthly(
            id: '',
            userId: user.uid,
            amount: amount,
            month: now.month,
            year: now.year,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await ref.read(firestoreServiceProvider).addBudget(budget);
          ref.invalidate(budgetsProvider);
          ref.invalidate(currentMonthBudgetProvider);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Budget created successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  void _showAddCategoryBudgetSheet(BuildContext context, WidgetRef ref) {
    // TODO: Implement category-specific budgets
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category budgets coming soon!')),
    );
  }
}

class _OverallBudgetCard extends ConsumerWidget {
  final AsyncValue<List<BudgetModel>> budgetsAsync;
  final AsyncValue<Map<String, double>> summaryAsync;

  const _OverallBudgetCard({
    required this.budgetsAsync,
    required this.summaryAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: budgetsAsync.when(
          data: (budgets) {
            final currentBudget = budgets.firstWhere(
              (b) => b.month == now.month && b.year == now.year && b.isActive,
              orElse: () => BudgetModel.monthly(
                id: '',
                userId: '',
                amount: 0,
                month: now.month,
                year: now.year,
                isActive: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            return summaryAsync.when(
              data: (summary) {
                final spent = summary['expense'] ?? 0;
                final totalBudget = currentBudget.amount;
                final remaining = totalBudget - spent;
                final percentUsed = totalBudget > 0 ? spent / totalBudget : 0.0;

                if (totalBudget == 0) {
                  return _NoBudgetState();
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Budget',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              now.monthYear,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: percentUsed > 0.8
                                ? AppColors.expense.withOpacity(0.1)
                                : AppColors.income.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(percentUsed * 100).toStringAsFixed(0)}% used',
                            style: TextStyle(
                              color: percentUsed > 0.8 ? AppColors.expense : AppColors.income,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Edit and Delete buttons
                    if (currentBudget.id.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showEditBudgetSheet(context, ref, currentBudget),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _showDeleteBudgetDialog(context, ref, currentBudget),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BudgetStat(
                          label: 'Budget',
                          amount: totalBudget,
                          color: AppColors.primary,
                        ),
                        _BudgetStat(
                          label: 'Spent',
                          amount: spent,
                          color: AppColors.expense,
                        ),
                        _BudgetStat(
                          label: 'Remaining',
                          amount: remaining > 0 ? remaining : 0,
                          color: remaining > 0 ? AppColors.income : AppColors.expense,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentUsed.clamp(0.0, 1.0),
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentUsed > 0.8 ? AppColors.expense : AppColors.primary,
                        ),
                        minHeight: 12,
                      ),
                    ),
                    if (remaining < 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: AppColors.expense, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Over budget by ${remaining.abs().currency}',
                              style: const TextStyle(
                                color: AppColors.expense,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading summary'),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Error loading budgets'),
        ),
      ),
    );
  }

  void _showEditBudgetSheet(BuildContext context, WidgetRef ref, BudgetModel budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditBudgetSheet(
        budget: budget,
        onSave: (amount) async {
          final updatedBudget = budget.copyWith(
            amount: amount,
            updatedAt: DateTime.now(),
          );
          await ref.read(firestoreServiceProvider).updateBudget(updatedBudget);
          ref.invalidate(budgetsProvider);
          ref.invalidate(currentMonthBudgetProvider);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Budget updated successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteBudgetDialog(BuildContext context, WidgetRef ref, BudgetModel budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete the budget for ${DateTime(budget.year, budget.month).monthYear}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(firestoreServiceProvider).deleteBudget(budget.id);
              ref.invalidate(budgetsProvider);
              ref.invalidate(currentMonthBudgetProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Budget deleted'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _NoBudgetState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.account_balance_wallet_outlined,
          size: 48,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 16),
        Text(
          'No budget set for this month',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Set a monthly budget to track your spending',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _BudgetStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          amount.currency,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _CategoryBudgetsList extends StatelessWidget {
  final AsyncValue<List<BudgetModel>> budgetsAsync;

  const _CategoryBudgetsList({required this.budgetsAsync});

  @override
  Widget build(BuildContext context) {
    return budgetsAsync.when(
      data: (budgets) {
        // Filter for category-specific budgets (if any)
        final categoryBudgets = budgets.where((b) => b.categoryId != null).toList();
        
        if (categoryBudgets.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No category budgets yet',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add category-specific budgets to track spending by category',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categoryBudgets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _CategoryBudgetCard(budget: categoryBudgets[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading budgets'),
    );
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  final BudgetModel budget;

  const _CategoryBudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    // Placeholder - will be expanded when category budgets are implemented
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.category, color: AppColors.primary),
        ),
        title: Text(budget.categoryId ?? 'Category'),
        subtitle: Text('Budget: ${budget.amount.currency}'),
      ),
    );
  }
}

class _CreateBudgetSheet extends StatefulWidget {
  final Function(double) onSave;

  const _CreateBudgetSheet({required this.onSave});

  @override
  State<_CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends State<_CreateBudgetSheet> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Set Monthly Budget',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Budget for ${now.monthYear}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Budget Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [10000, 20000, 30000, 50000].map((amount) {
                return ActionChip(
                  label: Text('₹${amount ~/ 1000}K'),
                  onPressed: () {
                    _amountController.text = amount.toString();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final amount = double.tryParse(_amountController.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid amount')),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);
                        await widget.onSave(amount);
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Set Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditBudgetSheet extends StatefulWidget {
  final BudgetModel budget;
  final Function(double) onSave;

  const _EditBudgetSheet({
    required this.budget,
    required this.onSave,
  });

  @override
  State<_EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends State<_EditBudgetSheet> {
  late final TextEditingController _amountController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.budget.amount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetDate = DateTime(widget.budget.year, widget.budget.month);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Budget',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Budget for ${budgetDate.monthYear}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Budget Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [10000, 20000, 30000, 50000].map((amount) {
                return ActionChip(
                  label: Text('₹${amount ~/ 1000}K'),
                  onPressed: () {
                    _amountController.text = amount.toString();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final amount = double.tryParse(_amountController.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid amount')),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);
                        await widget.onSave(amount);
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
