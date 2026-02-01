import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/models/models.dart';

/// Data class for split configuration
class SplitConfig {
  final bool isSplit;
  final String? paidByPersonId; // null means "Me"
  final String paidByPersonName;
  final double myShare;
  final List<SplitDetailModel> splits;

  const SplitConfig({
    this.isSplit = false,
    this.paidByPersonId,
    this.paidByPersonName = 'Me',
    this.myShare = 0,
    this.splits = const [],
  });

  SplitConfig copyWith({
    bool? isSplit,
    String? paidByPersonId,
    String? paidByPersonName,
    double? myShare,
    List<SplitDetailModel>? splits,
  }) {
    return SplitConfig(
      isSplit: isSplit ?? this.isSplit,
      paidByPersonId: paidByPersonId ?? this.paidByPersonId,
      paidByPersonName: paidByPersonName ?? this.paidByPersonName,
      myShare: myShare ?? this.myShare,
      splits: splits ?? this.splits,
    );
  }
}

/// Widget for configuring split transactions
class SplitTransactionWidget extends ConsumerStatefulWidget {
  final double totalAmount;
  final SplitConfig config;
  final ValueChanged<SplitConfig> onConfigChanged;

  const SplitTransactionWidget({
    super.key,
    required this.totalAmount,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  ConsumerState<SplitTransactionWidget> createState() =>
      _SplitTransactionWidgetState();
}

class _SplitTransactionWidgetState
    extends ConsumerState<SplitTransactionWidget> {
  late bool _isSplit;
  String? _paidByPersonId;
  String _paidByPersonName = 'Me';
  final Map<String, double> _splitAmounts = {};
  final Map<String, bool> _selectedPersons = {};
  bool _isEqualSplit = true;

  @override
  void initState() {
    super.initState();
    _isSplit = widget.config.isSplit;
    _paidByPersonId = widget.config.paidByPersonId;
    _paidByPersonName = widget.config.paidByPersonName;

    // Initialize from existing config
    for (final split in widget.config.splits) {
      if (split.personId != null) {
        _selectedPersons[split.personId!] = true;
        _splitAmounts[split.personId!] = split.amount;
      }
    }
  }

  @override
  void didUpdateWidget(SplitTransactionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount && _isSplit) {
      _recalculateSplits();
    }
  }

  void _recalculateSplits() {
    if (!_isSplit || widget.totalAmount <= 0) return;

    final selectedCount =
        _selectedPersons.values.where((v) => v).length + 1; // +1 for me

    if (_isEqualSplit && selectedCount > 0) {
      final equalShare = widget.totalAmount / selectedCount;

      for (final personId in _selectedPersons.keys) {
        if (_selectedPersons[personId] == true) {
          _splitAmounts[personId] = equalShare;
        }
      }
    }

    _notifyConfigChanged();
  }

  void _notifyConfigChanged() {
    if (!_isSplit) {
      widget.onConfigChanged(const SplitConfig(isSplit: false));
      return;
    }

    final selectedCount = _selectedPersons.values.where((v) => v).length + 1;
    final myShare = _isEqualSplit
        ? widget.totalAmount / selectedCount
        : widget.totalAmount -
              _splitAmounts.values.fold<double>(
                0,
                (sum, amount) => sum + amount,
              );

    final splits = <SplitDetailModel>[
      // Me
      SplitDetailModel(
        id: 'me',
        transactionId: '',
        personId: null,
        personName: 'Me',
        amount: myShare,
        isPayer: _paidByPersonId == null,
      ),
    ];

    // Add selected persons
    final persons = ref.read(personsProvider).valueOrNull ?? [];
    for (final entry in _selectedPersons.entries) {
      if (entry.value) {
        final person = persons.firstWhere(
          (p) => p.id == entry.key,
          orElse: () => PersonModel(
            id: entry.key,
            userId: '',
            name: 'Unknown',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        splits.add(
          SplitDetailModel(
            id: entry.key,
            transactionId: '',
            personId: entry.key,
            personName: person.name,
            amount: _splitAmounts[entry.key] ?? 0,
            isPayer: _paidByPersonId == entry.key,
          ),
        );
      }
    }

    widget.onConfigChanged(
      SplitConfig(
        isSplit: true,
        paidByPersonId: _paidByPersonId,
        paidByPersonName: _paidByPersonName,
        myShare: myShare,
        splits: splits,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(personsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Split toggle
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Split this expense',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            _isSplit ? 'Splitting with friends' : 'Not splitting',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          secondary: Icon(
            Icons.call_split,
            color: _isSplit ? AppColors.primary : AppColors.textSecondary,
          ),
          value: _isSplit,
          onChanged: (value) {
            setState(() {
              _isSplit = value;
              if (value) {
                _recalculateSplits();
              } else {
                _notifyConfigChanged();
              }
            });
          },
        ),

        if (_isSplit) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Who paid selector
          _buildPayerSelector(personsAsync),
          const SizedBox(height: 20),

          // People selector
          _buildPeopleSelector(personsAsync),
          const SizedBox(height: 20),

          // Split type selector
          _buildSplitTypeSelector(),
          const SizedBox(height: 16),

          // Split breakdown
          _buildSplitBreakdown(personsAsync),
        ],
      ],
    );
  }

  Widget _buildPayerSelector(AsyncValue<List<PersonModel>> personsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paid by',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        personsAsync.when(
          data: (persons) {
            final options = [
              {'id': null, 'name': 'Me'},
              ...persons.map((p) => {'id': p.id, 'name': p.name}),
            ];

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final optionId = option['id'];
                final isSelected = _paidByPersonId == optionId;
                return ChoiceChip(
                  label: Text(option['name'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _paidByPersonId = optionId is String ? optionId : null;
                        _paidByPersonName = option['name'] as String;
                        _notifyConfigChanged();
                      });
                    }
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error loading friends'),
        ),
      ],
    );
  }

  Widget _buildPeopleSelector(AsyncValue<List<PersonModel>> personsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Split with',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddPersonDialog(),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Friend'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        personsAsync.when(
          data: (persons) {
            if (persons.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add friends to split expenses with them',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: persons.map((person) {
                final isSelected = _selectedPersons[person.id] == true;
                return FilterChip(
                  label: Text(person.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPersons[person.id] = selected;
                      if (selected && _isEqualSplit) {
                        _recalculateSplits();
                      } else if (!selected) {
                        _splitAmounts.remove(person.id);
                        _notifyConfigChanged();
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error loading friends'),
        ),
      ],
    );
  }

  Widget _buildSplitTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _SplitTypeOption(
            label: 'Equal Split',
            icon: Icons.drag_handle,
            isSelected: _isEqualSplit,
            onTap: () {
              setState(() {
                _isEqualSplit = true;
                _recalculateSplits();
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SplitTypeOption(
            label: 'Custom Split',
            icon: Icons.tune,
            isSelected: !_isEqualSplit,
            onTap: () {
              setState(() {
                _isEqualSplit = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSplitBreakdown(AsyncValue<List<PersonModel>> personsAsync) {
    final selectedCount = _selectedPersons.values.where((v) => v).length + 1;
    final myShare = _isEqualSplit && widget.totalAmount > 0
        ? widget.totalAmount / selectedCount
        : widget.totalAmount -
              _splitAmounts.values.fold<double>(
                0,
                (sum, amount) => sum + amount,
              );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Split Breakdown',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // My share
          _SplitRow(
            name: 'Me',
            amount: myShare,
            isPayer: _paidByPersonId == null,
            isEditable: !_isEqualSplit,
            onAmountChanged: null, // Me's share is calculated from remaining
          ),

          // Selected persons
          personsAsync.when(
            data: (persons) {
              final selectedPersons = persons.where(
                (p) => _selectedPersons[p.id] == true,
              );

              return Column(
                children: selectedPersons.map((person) {
                  final amount = _isEqualSplit
                      ? widget.totalAmount / selectedCount
                      : (_splitAmounts[person.id] ?? 0);

                  return _SplitRow(
                    name: person.name,
                    amount: amount,
                    isPayer: _paidByPersonId == person.id,
                    isEditable: !_isEqualSplit,
                    onAmountChanged: !_isEqualSplit
                        ? (newAmount) {
                            setState(() {
                              _splitAmounts[person.id] = newAmount;
                              _notifyConfigChanged();
                            });
                          }
                        : null,
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Divider(height: 24),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddPersonDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
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

              await ref
                  .read(personsNotifierProvider.notifier)
                  .addPerson(name: name);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _SplitTypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SplitTypeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitRow extends StatefulWidget {
  final String name;
  final double amount;
  final bool isPayer;
  final bool isEditable;
  final ValueChanged<double>? onAmountChanged;

  const _SplitRow({
    required this.name,
    required this.amount,
    required this.isPayer,
    required this.isEditable,
    this.onAmountChanged,
  });

  @override
  State<_SplitRow> createState() => _SplitRowState();
}

class _SplitRowState extends State<_SplitRow> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.amount.toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(_SplitRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if amount changed externally (e.g., equal split recalculation)
    if (oldWidget.amount != widget.amount && !_controller.text.contains(widget.amount.toStringAsFixed(2))) {
      _controller.text = widget.amount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              widget.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name),
                if (widget.isPayer)
                  Text(
                    'Paid',
                    style: TextStyle(color: colorScheme.primary, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (widget.isEditable && widget.onAmountChanged != null)
            SizedBox(
              width: 100,
              child: TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.end,
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final newAmount = double.tryParse(value) ?? 0;
                  widget.onAmountChanged!(newAmount);
                },
              ),
            )
          else
            Text(
              '₹${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }
}
