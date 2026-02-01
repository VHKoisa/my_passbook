import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/models.dart';
import 'local_storage_service.dart';
import 'firestore_service.dart';
import 'connectivity_service.dart';
import '../providers/providers.dart';
import '../../main.dart' show localStorageServiceProvider;

/// Provider for local storage service
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

/// Sync service that handles offline/online data synchronization
class SyncService {
  final LocalStorageService _localStorage;
  final FirestoreService _firestoreService;
  final ConnectivityService _connectivityService;

  SyncService(this._localStorage, this._firestoreService, this._connectivityService);

  /// Sync pending operations when back online
  Future<SyncResult> syncPendingOperations(String userId) async {
    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    final pendingOps = _localStorage.getPendingSyncOperations(userId);
    if (pendingOps.isEmpty) {
      return SyncResult(success: true, message: 'Nothing to sync', syncedCount: 0);
    }

    int successCount = 0;
    int failCount = 0;

    for (final op in pendingOps) {
      try {
        await _executeSyncOperation(op);
        await _localStorage.removePendingSync(userId, op.timestamp);
        successCount++;
      } catch (e) {
        failCount++;
        // Keep failed operations in queue for retry
      }
    }

    if (failCount > 0) {
      return SyncResult(
        success: false,
        message: 'Synced $successCount, failed $failCount',
        syncedCount: successCount,
        failedCount: failCount,
      );
    }

    return SyncResult(
      success: true,
      message: 'All data synced',
      syncedCount: successCount,
    );
  }

  Future<void> _executeSyncOperation(PendingSyncOperation op) async {
    switch (op.collection) {
      case 'transactions':
        await _syncTransaction(op);
        break;
      case 'categories':
        await _syncCategory(op);
        break;
      case 'budgets':
        await _syncBudget(op);
        break;
    }
  }

  Future<void> _syncTransaction(PendingSyncOperation op) async {
    switch (op.operation) {
      case 'add':
        if (op.data != null) {
          final transaction = TransactionModel.fromJson(op.data!);
          await _firestoreService.addTransaction(transaction);
        }
        break;
      case 'update':
        if (op.data != null) {
          final transaction = TransactionModel.fromJson(op.data!);
          await _firestoreService.updateTransaction(transaction);
        }
        break;
      case 'delete':
        await _firestoreService.deleteTransaction(op.documentId);
        break;
    }
  }

  Future<void> _syncCategory(PendingSyncOperation op) async {
    switch (op.operation) {
      case 'add':
        if (op.data != null) {
          final category = CategoryModel.fromJson(op.data!);
          await _firestoreService.addCategory(category);
        }
        break;
      case 'update':
        if (op.data != null) {
          final category = CategoryModel.fromJson(op.data!);
          await _firestoreService.updateCategory(category);
        }
        break;
      case 'delete':
        await _firestoreService.deleteCategory(op.documentId);
        break;
    }
  }

  Future<void> _syncBudget(PendingSyncOperation op) async {
    switch (op.operation) {
      case 'add':
        if (op.data != null) {
          final budget = BudgetModel.fromJson(op.data!);
          await _firestoreService.addBudget(budget);
        }
        break;
      case 'update':
        if (op.data != null) {
          final budget = BudgetModel.fromJson(op.data!);
          await _firestoreService.updateBudget(budget);
        }
        break;
      case 'delete':
        await _firestoreService.deleteBudget(op.documentId);
        break;
    }
  }

  /// Cache data from Firestore for offline use
  Future<void> cacheAllData(String userId) async {
    try {
      // Cache transactions
      final transactionsStream = _firestoreService.streamTransactions();
      await transactionsStream.first.then((transactions) {
        _localStorage.cacheTransactions(userId, transactions);
      });

      // Cache categories
      final categoriesStream = _firestoreService.streamCategories();
      await categoriesStream.first.then((categories) {
        _localStorage.cacheCategories(userId, categories);
      });

      // Cache budgets
      final budgetsStream = _firestoreService.streamBudgets();
      await budgetsStream.first.then((budgets) {
        _localStorage.cacheBudgets(userId, budgets);
      });
    } catch (e) {
      // Silently fail - cached data will be used
    }
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.failedCount = 0,
  });
}

/// Provider for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(localStorageServiceProvider),
    ref.watch(firestoreServiceProvider),
    ref.watch(connectivityServiceProvider),
  );
});
