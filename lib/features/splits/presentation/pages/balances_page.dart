import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/models/models.dart';

class BalancesPage extends ConsumerWidget {
  const BalancesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(personBalancesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balances'),
        actions: [
          IconButton(
            onPressed: () => context.push('/persons'),
            icon: const Icon(Icons.people_outline),
            tooltip: 'Manage Friends',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(personBalancesProvider);
        },
        child: balancesAsync.when(
          data: (balances) {
            if (balances.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildBalancesList(context, ref, balances);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'All settled up!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Split a transaction to see balances here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalancesList(
    BuildContext context,
    WidgetRef ref,
    List<PersonBalanceModel> balances,
  ) {
    // Calculate totals
    double totalOwedToMe = 0;
    double totalIOwe = 0;

    for (final balance in balances) {
      if (balance.theyOweMe) {
        totalOwedToMe += balance.balance;
      } else if (balance.iOweThem) {
        totalIOwe += balance.balance.abs();
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        _SummaryCard(totalOwedToMe: totalOwedToMe, totalIOwe: totalIOwe),
        const SizedBox(height: 24),

        // Balances list
        Text(
          'Individual Balances',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ...balances.map(
          (balance) => _BalanceCard(
            balance: balance,
            onSettleUp: () => _showSettleUpDialog(context, ref, balance),
          ),
        ),
      ],
    );
  }

  void _showSettleUpDialog(
    BuildContext context,
    WidgetRef ref,
    PersonBalanceModel balance,
  ) {
    final amountController = TextEditingController(
      text: balance.absoluteBalance.toStringAsFixed(2),
    );
    final noteController = TextEditingController();
    bool settledByMe = balance.iOweThem; // If I owe them, I'm paying them

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Settle up with ${balance.personName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current balance info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: balance.theyOweMe
                        ? AppColors.income.withValues(alpha: 0.1)
                        : AppColors.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        balance.theyOweMe
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: balance.theyOweMe
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          balance.theyOweMe
                              ? '${balance.personName} owes you'
                              : 'You owe ${balance.personName}',
                          style: TextStyle(
                            color: balance.theyOweMe
                                ? AppColors.income
                                : AppColors.expense,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '₹${balance.absoluteBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: balance.theyOweMe
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Settlement direction
                const Text(
                  'Who is paying?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SettlementOption(
                        label: 'I paid',
                        isSelected: settledByMe,
                        onTap: () => setState(() => settledByMe = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SettlementOption(
                        label: '${balance.personName} paid',
                        isSelected: !settledByMe,
                        onTap: () => setState(() => settledByMe = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Amount
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Note
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
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
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                await ref
                    .read(personsNotifierProvider.notifier)
                    .addSettlement(
                      personId: balance.personId,
                      personName: balance.personName,
                      amount: amount,
                      settledByMe: settledByMe,
                      note: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    );

                // Refresh balances
                ref.invalidate(personBalancesProvider);
              },
              child: const Text('Record Settlement'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalOwedToMe;
  final double totalIOwe;

  const _SummaryCard({required this.totalOwedToMe, required this.totalIOwe});

  @override
  Widget build(BuildContext context) {
    final netBalance = totalOwedToMe - totalIOwe;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Net Balance',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '${netBalance >= 0 ? '+' : ''}₹${netBalance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: netBalance >= 0 ? AppColors.income : AppColors.expense,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              netBalance >= 0 ? 'Overall, you are owed' : 'Overall, you owe',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'You owe',
                    amount: totalIOwe,
                    color: AppColors.expense,
                    icon: Icons.arrow_upward,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.divider),
                Expanded(
                  child: _SummaryItem(
                    label: 'You are owed',
                    amount: totalOwedToMe,
                    color: AppColors.income,
                    icon: Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final PersonBalanceModel balance;
  final VoidCallback onSettleUp;

  const _BalanceCard({required this.balance, required this.onSettleUp});

  @override
  Widget build(BuildContext context) {
    final isOwedToMe = balance.theyOweMe;
    final color = isOwedToMe ? AppColors.income : AppColors.expense;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Text(
                balance.personName.substring(0, 1).toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),

            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balance.personName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOwedToMe ? 'owes you' : 'you owe',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Amount and settle button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${balance.absoluteBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onSettleUp,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Settle up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettlementOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SettlementOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
