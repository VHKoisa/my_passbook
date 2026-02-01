import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Income', 'Expense'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter bottom sheet
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                  ),
                );
              }).toList(),
            ),
          ),

          // Transactions List
          Expanded(
            child: _TransactionsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TransactionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Sample grouped transactions
    final groupedTransactions = {
      'Today': [
        _TransactionData(
          icon: Icons.restaurant,
          color: AppColors.categoryColors[0],
          title: 'Food & Dining',
          description: 'Lunch at restaurant',
          amount: -500,
          time: '12:30 PM',
        ),
        _TransactionData(
          icon: Icons.shopping_bag,
          color: AppColors.categoryColors[2],
          title: 'Shopping',
          description: 'Groceries',
          amount: -1200,
          time: '10:00 AM',
        ),
      ],
      'Yesterday': [
        _TransactionData(
          icon: Icons.directions_car,
          color: AppColors.categoryColors[1],
          title: 'Transportation',
          description: 'Uber ride',
          amount: -150,
          time: '6:30 PM',
        ),
        _TransactionData(
          icon: Icons.movie,
          color: AppColors.categoryColors[3],
          title: 'Entertainment',
          description: 'Movie tickets',
          amount: -400,
          time: '3:00 PM',
        ),
      ],
      'This Week': [
        _TransactionData(
          icon: Icons.account_balance_wallet,
          color: AppColors.income,
          title: 'Salary',
          description: 'Monthly salary',
          amount: 50000,
          time: 'Jan 1',
        ),
      ],
    };

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final date = groupedTransactions.keys.elementAt(index);
        final transactions = groupedTransactions[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                date,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) => _TransactionTile(
                  data: transactions[i],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TransactionData {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final double amount;
  final String time;

  const _TransactionData({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.amount,
    required this.time,
  });
}

class _TransactionTile extends StatelessWidget {
  final _TransactionData data;

  const _TransactionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final isExpense = data.amount < 0;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: data.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(data.icon, color: data.color),
      ),
      title: Text(data.title),
      subtitle: Text(data.description),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isExpense ? '-' : '+'}${data.amount.abs().currency}',
            style: TextStyle(
              color: isExpense ? AppColors.expense : AppColors.income,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            data.time,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      onTap: () {
        // TODO: Navigate to transaction details
      },
    );
  }
}
