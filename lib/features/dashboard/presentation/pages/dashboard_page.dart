import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            _BalanceCard(),
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
            _RecentTransactionsList(),
            const SizedBox(height: 24),

            // Spending Overview
            _SectionHeader(
              title: 'This Month',
              onSeeAll: () => context.go('/reports'),
            ),
            const SizedBox(height: 12),
            _SpendingOverview(),
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (25000.00).currency,
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
                  amount: (50000.00).currency,
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
                  amount: (25000.00).currency,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
        ],
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
          icon: Icons.swap_horiz,
          label: 'Transfer',
          color: AppColors.info,
          onTap: () {},
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
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text('See All'),
        ),
      ],
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Sample data - will be replaced with actual data
    final transactions = [
      _TransactionItem(
        icon: Icons.restaurant,
        color: AppColors.categoryColors[0],
        title: 'Food & Dining',
        subtitle: 'Today',
        amount: -500,
      ),
      _TransactionItem(
        icon: Icons.directions_car,
        color: AppColors.categoryColors[1],
        title: 'Transportation',
        subtitle: 'Yesterday',
        amount: -150,
      ),
      _TransactionItem(
        icon: Icons.account_balance_wallet,
        color: AppColors.income,
        title: 'Salary',
        subtitle: 'Jan 1',
        amount: 50000,
      ),
    ];

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => transactions[index],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final double amount;

  const _TransactionItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = amount < 0;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        '${isExpense ? '-' : '+'}${amount.abs().currency}',
        style: TextStyle(
          color: isExpense ? AppColors.expense : AppColors.income,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SpendingOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _OverviewItem(
                  label: 'Spent',
                  amount: (25000.00).currency,
                  color: AppColors.expense,
                ),
                _OverviewItem(
                  label: 'Budget',
                  amount: (40000.00).currency,
                  color: AppColors.primary,
                ),
                _OverviewItem(
                  label: 'Remaining',
                  amount: (15000.00).currency,
                  color: AppColors.income,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.625,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '62.5% of budget used',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
