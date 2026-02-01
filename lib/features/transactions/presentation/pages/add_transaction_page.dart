import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/models/transaction_model.dart';

class AddTransactionPage extends StatefulWidget {
  final String? initialType;

  const AddTransactionPage({super.key, this.initialType});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _selectedType;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType == 'income'
        ? TransactionType.income
        : TransactionType.expense;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
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
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Save to Firebase
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addTransaction),
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
                onChanged: (type) => setState(() => _selectedType = type),
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
                type: _selectedType,
                selectedCategoryId: _selectedCategoryId,
                onChanged: (id) => setState(() => _selectedCategoryId = id),
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
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: AppStrings.save,
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
  final TransactionType type;
  final String? selectedCategoryId;
  final ValueChanged<String> onChanged;

  const _CategorySelector({
    required this.type,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Sample categories - will be replaced with actual data
    final categories = type == TransactionType.expense
        ? [
            {'id': 'food', 'name': 'Food & Dining', 'icon': Icons.restaurant},
            {'id': 'transport', 'name': 'Transportation', 'icon': Icons.directions_car},
            {'id': 'shopping', 'name': 'Shopping', 'icon': Icons.shopping_bag},
            {'id': 'entertainment', 'name': 'Entertainment', 'icon': Icons.movie},
            {'id': 'bills', 'name': 'Bills & Utilities', 'icon': Icons.receipt_long},
            {'id': 'health', 'name': 'Health', 'icon': Icons.local_hospital},
          ]
        : [
            {'id': 'salary', 'name': 'Salary', 'icon': Icons.account_balance_wallet},
            {'id': 'freelance', 'name': 'Freelance', 'icon': Icons.laptop},
            {'id': 'investments', 'name': 'Investments', 'icon': Icons.trending_up},
            {'id': 'gifts', 'name': 'Gifts', 'icon': Icons.card_giftcard},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.category,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSelected = selectedCategoryId == cat['id'];
            final color = AppColors.categoryColors[
                categories.indexOf(cat) % AppColors.categoryColors.length];

            return GestureDetector(
              onTap: () => onChanged(cat['id'] as String),
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
                      cat['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat['name'] as String,
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
