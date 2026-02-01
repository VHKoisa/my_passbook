import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/models/models.dart';

class PersonsPage extends ConsumerStatefulWidget {
  const PersonsPage({super.key});

  @override
  ConsumerState<PersonsPage> createState() => _PersonsPageState();
}

class _PersonsPageState extends ConsumerState<PersonsPage> {
  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(personsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: personsAsync.when(
        data: (persons) {
          if (persons.isEmpty) {
            return _buildEmptyState();
          }
          return _buildPersonsList(persons);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditPersonDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Friend'),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No friends added yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add friends to split expenses with them',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonsList(List<PersonModel> persons) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: persons.length,
      itemBuilder: (context, index) {
        final person = persons[index];
        return _PersonCard(
          person: person,
          onEdit: () => _showAddEditPersonDialog(person: person),
          onDelete: () => _showDeleteConfirmation(person),
        );
      },
    );
  }

  void _showAddEditPersonDialog({PersonModel? person}) {
    final isEditing = person != null;
    final nameController = TextEditingController(text: person?.name ?? '');
    final phoneController = TextEditingController(text: person?.phone ?? '');
    final emailController = TextEditingController(text: person?.email ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Friend' : 'Add Friend'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }

              Navigator.pop(context);

              final notifier = ref.read(personsNotifierProvider.notifier);

              if (isEditing) {
                await notifier.updatePerson(
                  person.copyWith(
                    name: name,
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    email: emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                  ),
                );
              } else {
                await notifier.addPerson(
                  name: name,
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                );
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing ? 'Friend updated' : 'Friend added',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(PersonModel person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Friend?'),
        content: Text(
          'Are you sure you want to delete ${person.name}? '
          'This will not delete split transactions with them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(personsNotifierProvider.notifier)
                  .deletePerson(person.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Friend deleted'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final PersonModel person;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PersonCard({
    required this.person,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            person.initials,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          person.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: person.phone != null || person.email != null
            ? Text(
                person.phone ?? person.email ?? '',
                style: theme.textTheme.bodySmall,
              )
            : null,
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: colorScheme.error),
                title: Text(
                  'Delete',
                  style: TextStyle(color: colorScheme.error),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
        ),
      ),
    );
  }
}
