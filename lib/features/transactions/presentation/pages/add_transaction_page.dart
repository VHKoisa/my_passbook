import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../splits/presentation/widgets/split_transaction_widget.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  final String? initialType;
  final TransactionModel? editTransaction;

  const AddTransactionPage({
    super.key,
    this.initialType,
    this.editTransaction,
  });

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _selectedType;
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isEditing = false;
  
  // Split configuration
  SplitConfig _splitConfig = const SplitConfig();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.editTransaction != null;
    
    if (_isEditing) {
      final t = widget.editTransaction!;
      _selectedType = t.type;
      _amountController.text = t.amount.toString();
      _descriptionController.text = t.description ?? '';
      _noteController.text = t.note ?? '';
      _selectedDate = t.date;
      
      // Load split config if editing a split transaction
      if (t.isSplit) {
        _splitConfig = SplitConfig(
          isSplit: true,
          paidByPersonId: t.paidByPersonId,
          paidByPersonName: t.paidByPersonName ?? 'Me',
          myShare: t.myShare ?? 0,
          splits: t.splits,
        );
      }
    } else {
      _selectedType = widget.initialType == 'income'
          ? TransactionType.income
          : TransactionType.expense;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _checkBudgetAlert(TransactionModel transaction) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final settings = notificationService.settings;
      
      if (!settings.budgetAlerts) return;

      // Get budgets for this category
      final budgets = ref.read(budgetsProvider).valueOrNull ?? [];
      final categoryBudget = budgets.where((b) => b.categoryId == transaction.categoryId).firstOrNull;
      
      if (categoryBudget == null) return;

      // Calculate total spent this month for this category
      final now = DateTime.now();
      final transactions = ref.read(transactionsProvider).valueOrNull ?? [];
      final monthlySpent = transactions
          .where((t) =>
              t.categoryId == transaction.categoryId &&
              t.type == TransactionType.expense &&
              t.date.month == now.month &&
              t.date.year == now.year)
          .fold<double>(0, (sum, t) => sum + t.amount);

      // Add the new transaction amount
      final totalSpent = monthlySpent + transaction.amount;
      final percentage = ((totalSpent / categoryBudget.amount) * 100).round();

      // Check if we should alert
      if (percentage >= settings.budgetAlertThreshold) {
        await notificationService.showBudgetAlert(
          categoryName: transaction.categoryName,
          spent: totalSpent,
          budget: categoryBudget.amount,
          percentage: percentage,
        );
      }
    } catch (e) {
      debugPrint('Error checking budget alert: $e');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      final transaction = TransactionModel(
        id: _isEditing ? widget.editTransaction!.id : '',
        userId: user.uid,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        categoryIcon: _selectedCategory!.icon,
        categoryColor: _selectedCategory!.color,
        amount: double.parse(_amountController.text),
        type: _selectedType,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        date: _selectedDate,
        createdAt: _isEditing ? widget.editTransaction!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        // Split fields
        isSplit: _splitConfig.isSplit,
        paidByPersonId: _splitConfig.isSplit ? _splitConfig.paidByPersonId : null,
        paidByPersonName: _splitConfig.isSplit ? _splitConfig.paidByPersonName : null,
        splits: _splitConfig.isSplit ? _splitConfig.splits : const [],
        myShare: _splitConfig.isSplit ? _splitConfig.myShare : null,
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      
      if (_isEditing) {
        await firestoreService.updateTransaction(transaction);
      } else {
        await firestoreService.addTransaction(transaction);
      }

      // Check budget alerts for expense transactions
      if (_selectedType == TransactionType.expense) {
        await _checkBudgetAlert(transaction);
      }

      // Invalidate providers to refresh data across the app
      ref.invalidate(transactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(monthlySummaryProvider);
      
      // Refresh balances if this is a split transaction
      if (_splitConfig.isSplit) {
        ref.invalidate(personBalancesProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Transaction updated' : 'Transaction added'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = _selectedType == TransactionType.expense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : AppStrings.addTransaction),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector
              _TypeSelector(
                selectedType: _selectedType,
                onChanged: (type) {
                  setState(() {
                    _selectedType = type;
                    _selectedCategory = null;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Amount Field
              _AmountField(
                controller: _amountController,
                type: _selectedType,
              ),
              const SizedBox(height: 24),

              // Category Selector
              _CategorySelector(
                categoriesAsync: categoriesAsync,
                selectedCategory: _selectedCategory,
                onChanged: (category) => setState(() => _selectedCategory = category),
              ),
              const SizedBox(height: 16),

              // Date Selector
              _DateSelector(
                selectedDate: _selectedDate,
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),

              // Description Field
              CustomTextField(
                controller: _descriptionController,
                label: AppStrings.description,
                hint: 'What was this for?',
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 16),

              // Note Field
              CustomTextField(
                controller: _noteController,
                label: AppStrings.note,
                hint: 'Add a note (optional)',
                prefixIcon: Icons.note_outlined,
                maxLines: 3,
              ),
              
              // Split Transaction Section (only for expenses)
              if (_selectedType == TransactionType.expense) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                SplitTransactionWidget(
                  totalAmount: double.tryParse(_amountController.text) ?? 0,
                  config: _splitConfig,
                  onConfigChanged: (config) {
                    setState(() => _splitConfig = config);
                  },
                ),
              ],
              
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: _isEditing ? 'Update' : AppStrings.save,
                onPressed: _saveTransaction,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onChanged;

  const _TypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              label: AppStrings.expense,
              icon: Icons.arrow_upward,
              color: AppColors.expense,
              isSelected: selectedType == TransactionType.expense,
              onTap: () => onChanged(TransactionType.expense),
            ),
          ),
          Expanded(
            child: _TypeButton(
              label: AppStrings.income,
              icon: Icons.arrow_downward,
              color: AppColors.income,
              isSelected: selectedType == TransactionType.income,
              onTap: () => onChanged(TransactionType.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final TransactionType type;

  const _AmountField({
    required this.controller,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final color = type == TransactionType.expense
        ? AppColors.expense
        : AppColors.income;

    return Column(
      children: [
        Text(
          AppStrings.amount,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₹',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            IntrinsicWidth(
              child: TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  if (double.tryParse(value) == null) {
                    return AppStrings.invalidAmount;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final AsyncValue<List<CategoryModel>> categoriesAsync;
  final CategoryModel? selectedCategory;
  final ValueChanged<CategoryModel> onChanged;

  const _CategorySelector({
    required this.categoriesAsync,
    required this.selectedCategory,
    required this.onChanged,
  });

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
      'receipt_long': Icons.receipt_long,
      'local_hospital': Icons.local_hospital,
      'laptop': Icons.laptop,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.category,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const Text('No categories found.'),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        // Initialize default categories
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirestoreService().initializeDefaultCategories(user.uid);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Default Categories'),
                    ),
                  ],
                ),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                final isSelected = selectedCategory?.id == category.id;
                final color = Color(category.color);

                return GestureDetector(
                  onTap: () => onChanged(category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconFromString(category.icon),
                          size: 18,
                          color: isSelected ? Colors.white : color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Error loading categories: $error'),
        ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const _DateSelector({
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      leading: const Icon(Icons.calendar_today_outlined),
      title: const Text(AppStrings.date),
      trailing: Text(
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
