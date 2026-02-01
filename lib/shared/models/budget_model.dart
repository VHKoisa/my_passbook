import 'package:equatable/equatable.dart';

enum BudgetPeriod { daily, weekly, monthly, yearly }

class BudgetModel extends Equatable {
  final String id;
  final String userId;
  final String? categoryId;
  final String? categoryName;
  final double amount;
  final double spent;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool alertEnabled;
  final double alertThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetModel({
    required this.id,
    required this.userId,
    this.categoryId,
    this.categoryName,
    required this.amount,
    this.spent = 0,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.alertEnabled = true,
    this.alertThreshold = 0.8,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remaining => amount - spent;
  double get percentUsed => amount > 0 ? (spent / amount) * 100 : 0;
  bool get isOverBudget => spent > amount;
  bool get isNearLimit => percentUsed >= (alertThreshold * 100);

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      alertEnabled: json['alertEnabled'] as bool? ?? true,
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble() ?? 0.8,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'spent': spent,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'alertEnabled': alertEnabled,
      'alertThreshold': alertThreshold,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    double? amount,
    double? spent,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? alertEnabled,
    double? alertThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        categoryName,
        amount,
        spent,
        period,
        startDate,
        endDate,
        isActive,
        alertEnabled,
        alertThreshold,
        createdAt,
        updatedAt,
      ];
}
