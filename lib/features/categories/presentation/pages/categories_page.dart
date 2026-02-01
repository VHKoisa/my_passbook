import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/models/models.dart';
import '../widgets/category_form_dialog.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Categories'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Expense'),
              Tab(text: 'Income'),
            ],
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        body: TabBarView(
          children: [
            _CategoryList(type: TransactionType.expense),
            _CategoryList(type: TransactionType.income),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddCategoryDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Add Category'),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        onSave: (category) async {
          final user = ref.read(currentUserProvider);
          if (user == null) return;

          final newCategory = category.copyWith(userId: user.uid);
          await ref.read(firestoreServiceProvider).addCategory(newCategory);

          // Refresh categories
          ref.invalidate(categoriesProvider);
          ref.invalidate(expenseCategoriesProvider);
          ref.invalidate(incomeCategoriesProvider);
        },
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final TransactionType type;

  const _CategoryList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = type == TransactionType.expense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return _EmptyState(type: type, ref: ref);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            ref.invalidate(expenseCategoriesProvider);
            ref.invalidate(incomeCategoriesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryTile(
                category: category,
                onEdit: () => _showEditDialog(context, ref, category),
                onDelete: () => _showDeleteDialog(context, ref, category),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text('Error loading categories'),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(categoriesProvider);
                ref.invalidate(expenseCategoriesProvider);
                ref.invalidate(incomeCategoriesProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        category: category,
        onSave: (updatedCategory) async {
          await ref
              .read(firestoreServiceProvider)
              .updateCategory(updatedCategory);

          ref.invalidate(categoriesProvider);
          ref.invalidate(expenseCategoriesProvider);
          ref.invalidate(incomeCategoriesProvider);
        },
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${category.name}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transactions using this category will keep their category name.',
                      style: TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(firestoreServiceProvider)
                    .deleteCategory(category.id);

                ref.invalidate(categoriesProvider);
                ref.invalidate(expenseCategoriesProvider);
                ref.invalidate(incomeCategoriesProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
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
      'fitness_center': Icons.fitness_center,
      'pets': Icons.pets,
      'child_care': Icons.child_care,
      'local_cafe': Icons.local_cafe,
      'local_bar': Icons.local_bar,
      'local_gas_station': Icons.local_gas_station,
      'local_grocery_store': Icons.local_grocery_store,
      'local_laundry_service': Icons.local_laundry_service,
      'local_parking': Icons.local_parking,
      'local_pharmacy': Icons.local_pharmacy,
      'savings': Icons.savings,
      'payments': Icons.payments,
      'account_balance': Icons.account_balance,
      'business': Icons.business,
      'real_estate_agent': Icons.real_estate_agent,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(category.color);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIconFromString(category.icon), color: color),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final TransactionType type;
  final WidgetRef ref;

  const _EmptyState({required this.type, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${type == TransactionType.expense ? 'expense' : 'income'} categories',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create default categories',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                await ref
                    .read(firestoreServiceProvider)
                    .initializeDefaultCategories(user.uid);
                ref.invalidate(categoriesProvider);
                ref.invalidate(expenseCategoriesProvider);
                ref.invalidate(incomeCategoriesProvider);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Default Categories'),
          ),
        ],
      ),
    );
  }
}
