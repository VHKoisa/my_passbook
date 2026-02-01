import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

class TransactionModel extends Equatable {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final int categoryColor;
  final double amount;
  final TransactionType type;
  final String? description;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? receiptUrl;
  final bool isRecurring;
  final String? recurringId;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.amount,
    required this.type,
    this.description,
    this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.receiptUrl,
    this.isRecurring = false,
    this.recurringId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      categoryIcon: json['categoryIcon'] as String,
      categoryColor: json['categoryColor'] as int,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      description: json['description'] as String?,
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      receiptUrl: json['receiptUrl'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringId: json['recurringId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'categoryColor': categoryColor,
      'amount': amount,
      'type': type.name,
      'description': description,
      'note': note,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'receiptUrl': receiptUrl,
      'isRecurring': isRecurring,
      'recurringId': recurringId,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    int? categoryColor,
    double? amount,
    TransactionType? type,
    String? description,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? receiptUrl,
    bool? isRecurring,
    String? recurringId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        categoryName,
        categoryIcon,
        categoryColor,
        amount,
        type,
        description,
        note,
        date,
        createdAt,
        updatedAt,
        receiptUrl,
        isRecurring,
        recurringId,
      ];
}
