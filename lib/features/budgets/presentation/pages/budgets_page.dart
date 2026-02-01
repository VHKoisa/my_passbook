import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to add budget
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Budget Card
            _OverallBudgetCard(),
            const SizedBox(height: 24),

            // Category Budgets
            Text(
              'Category Budgets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _CategoryBudgetsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add budget
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
    );
  }
}

class _OverallBudgetCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const totalBudget = 50000.0;
    const spent = 32000.0;
    const remaining = totalBudget - spent;
    const percentUsed = spent / totalBudget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
                      'February 2026',
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
            const SizedBox(height: 24),
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
                  amount: remaining,
                  color: AppColors.income,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentUsed,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentUsed > 0.8 ? AppColors.expense : AppColors.primary,
                ),
                minHeight: 12,
              ),
            ),
          ],
        ),
      ),
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
  @override
  Widget build(BuildContext context) {
    final budgets = [
      _BudgetData(
        name: 'Food & Dining',
        icon: Icons.restaurant,
        color: AppColors.categoryColors[0],
        budget: 10000,
        spent: 7500,
      ),
      _BudgetData(
        name: 'Transportation',
        icon: Icons.directions_car,
        color: AppColors.categoryColors[1],
        budget: 5000,
        spent: 4200,
      ),
      _BudgetData(
        name: 'Shopping',
        icon: Icons.shopping_bag,
        color: AppColors.categoryColors[2],
        budget: 8000,
        spent: 9500,
      ),
      _BudgetData(
        name: 'Entertainment',
        icon: Icons.movie,
        color: AppColors.categoryColors[3],
        budget: 3000,
        spent: 1800,
      ),
      _BudgetData(
        name: 'Bills & Utilities',
        icon: Icons.receipt_long,
        color: AppColors.categoryColors[4],
        budget: 15000,
        spent: 9000,
      ),
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: budgets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _CategoryBudgetCard(data: budgets[index]),
    );
  }
}

class _BudgetData {
  final String name;
  final IconData icon;
  final Color color;
  final double budget;
  final double spent;

  const _BudgetData({
    required this.name,
    required this.icon,
    required this.color,
    required this.budget,
    required this.spent,
  });

  double get remaining => budget - spent;
  double get percentUsed => spent / budget;
  bool get isOverBudget => spent > budget;
}

class _CategoryBudgetCard extends StatelessWidget {
  final _BudgetData data;

  const _CategoryBudgetCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon, color: data.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.spent.currency} of ${data.budget.currency}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data.isOverBudget
                          ? '-${data.remaining.abs().currency}'
                          : data.remaining.currency,
                      style: TextStyle(
                        color: data.isOverBudget
                            ? AppColors.expense
                            : AppColors.income,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      data.isOverBudget ? 'Over budget' : 'Remaining',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: data.percentUsed.clamp(0, 1),
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  data.isOverBudget ? AppColors.expense : data.color,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
