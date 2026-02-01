import 'package:equatable/equatable.dart';

/// Model for split details in a transaction
class SplitDetailModel extends Equatable {
  final String id;
  final String transactionId;
  final String? personId; // null means "me" (the current user)
  final String personName; // "Me" or person's name
  final double amount; // Amount this person owes/is owed
  final bool isPayer; // Whether this person paid for the transaction
  final bool isSettled; // Whether this split has been settled
  final DateTime? settledAt;

  const SplitDetailModel({
    required this.id,
    required this.transactionId,
    this.personId,
    required this.personName,
    required this.amount,
    this.isPayer = false,
    this.isSettled = false,
    this.settledAt,
  });

  /// Check if this is the current user's split
  bool get isMe => personId == null;

  factory SplitDetailModel.fromJson(Map<String, dynamic> json) {
    return SplitDetailModel(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      personId: json['personId'] as String?,
      personName: json['personName'] as String,
      amount: (json['amount'] as num).toDouble(),
      isPayer: json['isPayer'] as bool? ?? false,
      isSettled: json['isSettled'] as bool? ?? false,
      settledAt: json['settledAt'] != null 
          ? DateTime.parse(json['settledAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'personId': personId,
      'personName': personName,
      'amount': amount,
      'isPayer': isPayer,
      'isSettled': isSettled,
      'settledAt': settledAt?.toIso8601String(),
    };
  }

  SplitDetailModel copyWith({
    String? id,
    String? transactionId,
    String? personId,
    String? personName,
    double? amount,
    bool? isPayer,
    bool? isSettled,
    DateTime? settledAt,
  }) {
    return SplitDetailModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      isPayer: isPayer ?? this.isPayer,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        transactionId,
        personId,
        personName,
        amount,
        isPayer,
        isSettled,
        settledAt,
      ];
}

/// Model for tracking balance with a person
class PersonBalanceModel extends Equatable {
  final String personId;
  final String personName;
  final double balance; // Positive = they owe me, Negative = I owe them
  final int transactionCount;

  const PersonBalanceModel({
    required this.personId,
    required this.personName,
    required this.balance,
    required this.transactionCount,
  });

  bool get theyOweMe => balance > 0;
  bool get iOweThem => balance < 0;
  bool get isSettled => balance.abs() < 0.01;
  double get absoluteBalance => balance.abs();

  PersonBalanceModel copyWith({
    String? personId,
    String? personName,
    double? balance,
    int? transactionCount,
  }) {
    return PersonBalanceModel(
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      balance: balance ?? this.balance,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }

  @override
  List<Object?> get props => [personId, personName, balance, transactionCount];
}

/// Model for a settlement transaction
class SettlementModel extends Equatable {
  final String id;
  final String userId;
  final String personId;
  final String personName;
  final double amount; // Always positive, direction determined by settledByMe
  final bool settledByMe; // true = I paid them, false = they paid me
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const SettlementModel({
    required this.id,
    required this.userId,
    required this.personId,
    required this.personName,
    required this.amount,
    this.settledByMe = true,
    this.note,
    required this.date,
    required this.createdAt,
  });

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    return SettlementModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String,
      personId: json['personId'] as String,
      personName: json['personName'] as String,
      amount: (json['amount'] as num).toDouble(),
      settledByMe: json['settledByMe'] as bool? ?? true,
      note: json['note'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'personId': personId,
      'personName': personName,
      'amount': amount,
      'settledByMe': settledByMe,
      'note': note,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, personId, personName, amount, settledByMe, note, date, createdAt];
}
