import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/models/models.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlySummary = ref.watch(monthlySummaryProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);
    final currentBudget = ref.watch(currentMonthBudgetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(monthlySummaryProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(currentMonthBudgetProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              _BalanceCard(summaryAsync: monthlySummary),
              const SizedBox(height: 24),

              // Quick Actions
              _QuickActions(),
              const SizedBox(height: 24),

              // Recent Transactions
              _SectionHeader(
                title: 'Recent Transactions',
                onSeeAll: () => context.go('/transactions'),
              ),
              const SizedBox(height: 12),
              _RecentTransactionsList(transactionsAsync: recentTransactions),
              const SizedBox(height: 24),

              // Spending Overview
              _SectionHeader(
                title: 'This Month',
                onSeeAll: () => context.go('/reports'),
              ),
              const SizedBox(height: 12),
              _SpendingOverview(
                summaryAsync: monthlySummary,
                budgetAsync: currentBudget,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-transaction'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final AsyncValue<Map<String, double>> summaryAsync;

  const _BalanceCard({required this.summaryAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: summaryAsync.when(
        data: (summary) {
          final income = summary['income'] ?? 0;
          final expense = summary['expense'] ?? 0;
          final balance = income - expense;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Month\'s Balance',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                balance.currency,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _BalanceItem(
                      icon: Icons.arrow_downward,
                      label: 'Income',
                      amount: income.currency,
                      color: AppColors.income,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _BalanceItem(
                      icon: Icons.arrow_upward,
                      label: 'Expense',
                      amount: expense.currency,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (_, __) => const Center(
          child: Text(
            'Error loading data',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  const _BalanceItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _QuickActionButton(
          icon: Icons.arrow_downward,
          label: 'Income',
          color: AppColors.income,
          onTap: () => context.push('/add-transaction?type=income'),
        ),
        _QuickActionButton(
          icon: Icons.arrow_upward,
          label: 'Expense',
          color: AppColors.expense,
          onTap: () => context.push('/add-transaction?type=expense'),
        ),
        _QuickActionButton(
          icon: Icons.call_split,
          label: 'Splits',
          color: AppColors.info,
          onTap: () => context.push('/balances'),
        ),
        _QuickActionButton(
          icon: Icons.account_balance_wallet,
          label: 'Budget',
          color: AppColors.warning,
          onTap: () => context.go('/budgets'),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
  final AsyncValue<List<TransactionModel>> transactionsAsync;

  const _RecentTransactionsList({required this.transactionsAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first transaction to get started',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _TransactionItem(transaction: transaction);
            },
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionItem({required this.transaction});

  IconData _getIconFromString(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_bag': Icons.shopping_bag,
      'movie': Icons.movie,
      'home': Icons.home,
      'medical_services': Icons.medical_services,
      'school': Icons.school,
      'flight': Icons.flight,
      'subscriptions': Icons.subscriptions,
      'attach_money': Icons.attach_money,
      'account_balance_wallet': Icons.account_balance_wallet,
      'work': Icons.work,
      'card_giftcard': Icons.card_giftcard,
      'trending_up': Icons.trending_up,
      'more_horiz': Icons.more_horiz,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = Color(transaction.categoryColor);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_getIconFromString(transaction.categoryIcon), color: color),
      ),
      title: Text(transaction.categoryName),
      subtitle: Text(
        transaction.description ?? transaction.date.formatDate,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${isExpense ? '-' : '+'}${transaction.amount.currency}',
        style: TextStyle(
          color: isExpense ? AppColors.expense : AppColors.income,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SpendingOverview extends StatelessWidget {
  final AsyncValue<Map<String, double>> summaryAsync;
  final AsyncValue<BudgetModel?> budgetAsync;

  const _SpendingOverview({
    required this.summaryAsync,
    required this.budgetAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: summaryAsync.when(
          data: (summary) {
            final spent = summary['expense'] ?? 0;

            return budgetAsync.when(
              data: (budget) {
                final budgetAmount = budget?.amount ?? 0;
                final remaining = budgetAmount > 0 ? budgetAmount - spent : 0;
                final progress = budgetAmount > 0
                    ? (spent / budgetAmount).clamp(0.0, 1.0)
                    : 0.0;
                final percentage = (progress * 100).toStringAsFixed(1);

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _OverviewItem(
                          label: 'Spent',
                          amount: spent.currency,
                          color: AppColors.expense,
                        ),
                        _OverviewItem(
                          label: 'Budget',
                          amount: budgetAmount > 0
                              ? budgetAmount.currency
                              : 'Not set',
                          color: AppColors.primary,
                        ),
                        _OverviewItem(
                          label: 'Remaining',
                          amount: remaining >= 0
                              ? remaining.currency
                              : 0.0.currency,
                          color: remaining >= 0
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      ],
                    ),
                    if (budgetAmount > 0) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.toDouble(),
                          backgroundColor: Theme.of(context).dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress > 0.8
                                ? AppColors.expense
                                : AppColors.primary,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$percentage% of budget used',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => context.go('/budgets'),
                        icon: const Icon(Icons.add),
                        label: const Text('Set a Budget'),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading budget'),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Error loading summary'),
        ),
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _OverviewItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
