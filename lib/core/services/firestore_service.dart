import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/models.dart';
import '../../../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // ==================== USER ====================

  /// Create or update user document
  Future<void> saveUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .set(user.toJson(), SetOptions(merge: true));
  }

  /// Get user by ID
  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  /// Stream user data
  Stream<UserModel?> streamUser(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromJson(doc.data()!) : null);
  }

  // ==================== TRANSACTIONS ====================

  /// Add a new transaction
  Future<String> addTransaction(TransactionModel transaction) async {
    final docRef = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.transactionsCollection)
        .add(transaction.toJson());
    return docRef.id;
  }

  /// Update a transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.transactionsCollection)
        .doc(transaction.id)
        .update(transaction.toJson());
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.transactionsCollection)
        .doc(transactionId)
        .delete();
  }

  /// Get all transactions for current user
  Stream<List<TransactionModel>> streamTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    String? categoryId,
    int? limit,
  }) {
    Query query = _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.transactionsCollection)
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate.toIso8601String());
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
        .toList());
  }

  /// Get transactions for a specific month
  Future<List<TransactionModel>> getMonthlyTransactions(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.transactionsCollection)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // ==================== CATEGORIES ====================

  /// Add a new category
  Future<String> addCategory(CategoryModel category) async {
    final docRef = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.categoriesCollection)
        .add(category.toJson());
    return docRef.id;
  }

  /// Update a category
  Future<void> updateCategory(CategoryModel category) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.categoriesCollection)
        .doc(category.id)
        .update(category.toJson());
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.categoriesCollection)
        .doc(categoryId)
        .delete();
  }

  /// Stream all categories
  Stream<List<CategoryModel>> streamCategories({TransactionType? type}) {
    Query query = _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.categoriesCollection)
        .orderBy('name');

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => CategoryModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
        .toList());
  }

  /// Initialize default categories for new user
  Future<void> initializeDefaultCategories(String userId) async {
    final batch = _firestore.batch();
    final categoriesRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.categoriesCollection);

    // Add expense categories
    for (final category in CategoryModel.defaultExpenseCategories) {
      final docRef = categoriesRef.doc();
      batch.set(docRef, category.copyWith(id: docRef.id, userId: userId).toJson());
    }

    // Add income categories
    for (final category in CategoryModel.defaultIncomeCategories) {
      final docRef = categoriesRef.doc();
      batch.set(docRef, category.copyWith(id: docRef.id, userId: userId).toJson());
    }

    await batch.commit();
  }

  // ==================== BUDGETS ====================

  /// Add a new budget
  Future<String> addBudget(BudgetModel budget) async {
    final docRef = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.budgetsCollection)
        .add(budget.toJson());
    return docRef.id;
  }

  /// Update a budget
  Future<void> updateBudget(BudgetModel budget) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.budgetsCollection)
        .doc(budget.id)
        .update(budget.toJson());
  }

  /// Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.budgetsCollection)
        .doc(budgetId)
        .delete();
  }

  /// Stream active budgets
  Stream<List<BudgetModel>> streamBudgets({bool activeOnly = true}) {
    Query query = _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.budgetsCollection);

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => BudgetModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
        .toList());
  }

  // ==================== STATISTICS ====================

  /// Get total income/expense for a period
  Future<Map<String, double>> getTransactionSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.transactionsCollection)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
        .get();

    double totalIncome = 0;
    double totalExpense = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      if (data['type'] == 'income') {
        totalIncome += amount;
      } else {
        totalExpense += amount;
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  /// Get spending by category
  Future<Map<String, double>> getSpendingByCategory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.transactionsCollection)
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
        .get();

    final Map<String, double> categoryTotals = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final categoryName = data['categoryName'] as String;
      final amount = (data['amount'] as num).toDouble();
      categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + amount;
    }

    return categoryTotals;
  }
}
