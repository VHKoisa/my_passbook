import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/models/models.dart';

/// Local storage service using Hive for offline support
class LocalStorageService {
  static const String _transactionsBox = 'transactions';
  static const String _categoriesBox = 'categories';
  static const String _budgetsBox = 'budgets';
  static const String _pendingSyncBox = 'pending_sync';
  static const String _metadataBox = 'metadata';

  late Box<Map> _transactionsBoxInstance;
  late Box<Map> _categoriesBoxInstance;
  late Box<Map> _budgetsBoxInstance;
  late Box<Map> _pendingSyncBoxInstance;
  late Box _metadataBoxInstance;

  bool _isInitialized = false;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    _transactionsBoxInstance = await Hive.openBox<Map>(_transactionsBox);
    _categoriesBoxInstance = await Hive.openBox<Map>(_categoriesBox);
    _budgetsBoxInstance = await Hive.openBox<Map>(_budgetsBox);
    _pendingSyncBoxInstance = await Hive.openBox<Map>(_pendingSyncBox);
    _metadataBoxInstance = await Hive.openBox(_metadataBox);

    _isInitialized = true;
  }

  // ==================== TRANSACTIONS ====================

  /// Cache transactions locally
  Future<void> cacheTransactions(String userId, List<TransactionModel> transactions) async {
    final data = <String, Map>{};
    for (final transaction in transactions) {
      data[transaction.id] = transaction.toJson();
    }
    await _transactionsBoxInstance.put(userId, data);
    await _setLastSyncTime(userId, 'transactions');
  }

  /// Get cached transactions
  List<TransactionModel> getCachedTransactions(String userId) {
    final data = _transactionsBoxInstance.get(userId);
    if (data == null) return [];

    return data.entries.map((entry) {
      final json = Map<String, dynamic>.from(entry.value as Map);
      json['id'] = entry.key;
      return TransactionModel.fromJson(json);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Add transaction to cache
  Future<void> addTransactionToCache(String userId, TransactionModel transaction) async {
    final data = Map<String, Map>.from(_transactionsBoxInstance.get(userId) ?? {});
    data[transaction.id] = transaction.toJson();
    await _transactionsBoxInstance.put(userId, data);
  }

  /// Update transaction in cache
  Future<void> updateTransactionInCache(String userId, TransactionModel transaction) async {
    await addTransactionToCache(userId, transaction);
  }

  /// Delete transaction from cache
  Future<void> deleteTransactionFromCache(String userId, String transactionId) async {
    final data = Map<String, Map>.from(_transactionsBoxInstance.get(userId) ?? {});
    data.remove(transactionId);
    await _transactionsBoxInstance.put(userId, data);
  }

  // ==================== CATEGORIES ====================

  /// Cache categories locally
  Future<void> cacheCategories(String userId, List<CategoryModel> categories) async {
    final data = <String, Map>{};
    for (final category in categories) {
      data[category.id] = category.toJson();
    }
    await _categoriesBoxInstance.put(userId, data);
    await _setLastSyncTime(userId, 'categories');
  }

  /// Get cached categories
  List<CategoryModel> getCachedCategories(String userId, {TransactionType? type}) {
    final data = _categoriesBoxInstance.get(userId);
    if (data == null) return [];

    var categories = data.entries.map((entry) {
      final json = Map<String, dynamic>.from(entry.value as Map);
      json['id'] = entry.key;
      return CategoryModel.fromJson(json);
    }).toList();

    if (type != null) {
      categories = categories.where((c) => c.type == type).toList();
    }

    return categories..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Add category to cache
  Future<void> addCategoryToCache(String userId, CategoryModel category) async {
    final data = Map<String, Map>.from(_categoriesBoxInstance.get(userId) ?? {});
    data[category.id] = category.toJson();
    await _categoriesBoxInstance.put(userId, data);
  }

  /// Delete category from cache
  Future<void> deleteCategoryFromCache(String userId, String categoryId) async {
    final data = Map<String, Map>.from(_categoriesBoxInstance.get(userId) ?? {});
    data.remove(categoryId);
    await _categoriesBoxInstance.put(userId, data);
  }

  // ==================== BUDGETS ====================

  /// Cache budgets locally
  Future<void> cacheBudgets(String userId, List<BudgetModel> budgets) async {
    final data = <String, Map>{};
    for (final budget in budgets) {
      data[budget.id] = budget.toJson();
    }
    await _budgetsBoxInstance.put(userId, data);
    await _setLastSyncTime(userId, 'budgets');
  }

  /// Get cached budgets
  List<BudgetModel> getCachedBudgets(String userId) {
    final data = _budgetsBoxInstance.get(userId);
    if (data == null) return [];

    return data.entries.map((entry) {
      final json = Map<String, dynamic>.from(entry.value as Map);
      json['id'] = entry.key;
      return BudgetModel.fromJson(json);
    }).toList();
  }

  /// Add budget to cache
  Future<void> addBudgetToCache(String userId, BudgetModel budget) async {
    final data = Map<String, Map>.from(_budgetsBoxInstance.get(userId) ?? {});
    data[budget.id] = budget.toJson();
    await _budgetsBoxInstance.put(userId, data);
  }

  // ==================== PENDING SYNC ====================

  /// Add operation to pending sync queue
  Future<void> addPendingSync(PendingSyncOperation operation) async {
    final key = '${operation.userId}_${operation.timestamp.millisecondsSinceEpoch}';
    await _pendingSyncBoxInstance.put(key, operation.toJson());
  }

  /// Get all pending sync operations for a user
  List<PendingSyncOperation> getPendingSyncOperations(String userId) {
    final operations = <PendingSyncOperation>[];
    
    for (final key in _pendingSyncBoxInstance.keys) {
      if (key.toString().startsWith('${userId}_')) {
        final data = _pendingSyncBoxInstance.get(key);
        if (data != null) {
          operations.add(PendingSyncOperation.fromJson(Map<String, dynamic>.from(data)));
        }
      }
    }

    return operations..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Remove pending sync operation
  Future<void> removePendingSync(String userId, DateTime timestamp) async {
    final key = '${userId}_${timestamp.millisecondsSinceEpoch}';
    await _pendingSyncBoxInstance.delete(key);
  }

  /// Clear all pending sync operations for a user
  Future<void> clearPendingSync(String userId) async {
    final keysToDelete = <String>[];
    for (final key in _pendingSyncBoxInstance.keys) {
      if (key.toString().startsWith('${userId}_')) {
        keysToDelete.add(key.toString());
      }
    }
    for (final key in keysToDelete) {
      await _pendingSyncBoxInstance.delete(key);
    }
  }

  // ==================== METADATA ====================

  Future<void> _setLastSyncTime(String userId, String collection) async {
    await _metadataBoxInstance.put('${userId}_${collection}_lastSync', DateTime.now().toIso8601String());
  }

  DateTime? getLastSyncTime(String userId, String collection) {
    final value = _metadataBoxInstance.get('${userId}_${collection}_lastSync');
    if (value == null) return null;
    return DateTime.parse(value);
  }

  /// Clear all cached data for a user
  Future<void> clearUserData(String userId) async {
    await _transactionsBoxInstance.delete(userId);
    await _categoriesBoxInstance.delete(userId);
    await _budgetsBoxInstance.delete(userId);
    await clearPendingSync(userId);
  }

  /// Clear all data (for logout)
  Future<void> clearAll() async {
    await _transactionsBoxInstance.clear();
    await _categoriesBoxInstance.clear();
    await _budgetsBoxInstance.clear();
    await _pendingSyncBoxInstance.clear();
    await _metadataBoxInstance.clear();
  }
}

/// Represents a pending sync operation
class PendingSyncOperation {
  final String userId;
  final String collection; // 'transactions', 'categories', 'budgets'
  final String operation; // 'add', 'update', 'delete'
  final String documentId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  PendingSyncOperation({
    required this.userId,
    required this.collection,
    required this.operation,
    required this.documentId,
    this.data,
    required this.timestamp,
  });

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    return PendingSyncOperation(
      userId: json['userId'] as String,
      collection: json['collection'] as String,
      operation: json['operation'] as String,
      documentId: json['documentId'] as String,
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'collection': collection,
      'operation': operation,
      'documentId': documentId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
