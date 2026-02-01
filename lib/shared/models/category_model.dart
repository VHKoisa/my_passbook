import 'package:equatable/equatable.dart';
import 'transaction_model.dart';

class CategoryModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final int color;
  final TransactionType type;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as int,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type.name,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    int? color,
    TransactionType? type,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        icon,
        color,
        type,
        isDefault,
        createdAt,
        updatedAt,
      ];

  // Default Categories
  static List<CategoryModel> get defaultExpenseCategories => [
        CategoryModel(
          id: 'food',
          userId: 'default',
          name: 'Food & Dining',
          icon: 'restaurant',
          color: 0xFFEF4444,
          type: TransactionType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'transport',
          userId: 'default',
          name: 'Transportation',
          icon: 'directions_car',
          color: 0xFF3B82F6,
          type: TransactionType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'shopping',
          userId: 'default',
          name: 'Shopping',
          icon: 'shopping_bag',
          color: 0xFF8B5CF6,
          type: TransactionType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'entertainment',
          userId: 'default',
          name: 'Entertainment',
          icon: 'movie',
          color: 0xFFF59E0B,
          type: TransactionType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'bills',
          userId: 'default',
          name: 'Bills & Utilities',
          icon: 'receipt_long',
          color: 0xFF06B6D4,
          type: TransactionType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'health',
          userId: 'default',
          name: 'Health & Medical',
          icon: 'local_hospital',
          color: 0xFFEC4899,
          type: TransactionType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'education',
          userId: 'default',
          name: 'Education',
          icon: 'school',
          color: 0xFF10B981,
          type: TransactionType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'other_expense',
          userId: 'default',
          name: 'Other',
          icon: 'more_horiz',
          color: 0xFF64748B,
          type: TransactionType.expense,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

  static List<CategoryModel> get defaultIncomeCategories => [
        CategoryModel(
          id: 'salary',
          userId: 'default',
          name: 'Salary',
          icon: 'account_balance_wallet',
          color: 0xFF10B981,
          type: TransactionType.income,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'freelance',
          userId: 'default',
          name: 'Freelance',
          icon: 'laptop',
          color: 0xFF6366F1,
          type: TransactionType.income,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'investments',
          userId: 'default',
          name: 'Investments',
          icon: 'trending_up',
          color: 0xFF3B82F6,
          type: TransactionType.income,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'gifts',
          userId: 'default',
          name: 'Gifts',
          icon: 'card_giftcard',
          color: 0xFFEC4899,
          type: TransactionType.income,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'other_income',
          userId: 'default',
          name: 'Other',
          icon: 'more_horiz',
          color: 0xFF64748B,
          type: TransactionType.income,
          isDefault: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
}
