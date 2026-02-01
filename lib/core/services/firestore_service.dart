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
        .collection(AppConstants.categoriesCollection);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    return query.snapshots().map((snapshot) {
      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
      // Sort client-side to avoid composite index requirement
      categories.sort((a, b) => a.name.compareTo(b.name));
      return categories;
    });
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

  /// Get budget for a specific month
  Future<BudgetModel?> getBudgetForMonth(int month, int year) async {
    try {
      // Get all active budgets and filter locally
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_userId)
          .collection(AppConstants.budgetsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return null;
      
      // Find budget matching the month/year
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Check if month/year fields exist (new format)
        if (data['month'] == month && data['year'] == year) {
          return BudgetModel.fromJson({...data, 'id': doc.id});
        }
        
        // Check by startDate (old format)
        if (data['startDate'] != null) {
          final startDate = DateTime.parse(data['startDate'] as String);
          if (startDate.month == month && startDate.year == year) {
            return BudgetModel.fromJson({...data, 'id': doc.id});
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting budget for month: $e');
      return null;
    }
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
      final isSplit = data['isSplit'] as bool? ?? false;
      final myShare = (data['myShare'] as num?)?.toDouble();
      final amount = (data['amount'] as num).toDouble();
      
      // Use myShare for split transactions, otherwise use full amount
      final effectiveAmount = isSplit && myShare != null ? myShare : amount;
      
      if (data['type'] == 'income') {
        totalIncome += effectiveAmount;
      } else {
        totalExpense += effectiveAmount;
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
      final isSplit = data['isSplit'] as bool? ?? false;
      final myShare = (data['myShare'] as num?)?.toDouble();
      final amount = (data['amount'] as num).toDouble();
      
      // Use myShare for split transactions
      final effectiveAmount = isSplit && myShare != null ? myShare : amount;
      
      categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + effectiveAmount;
    }

    return categoryTotals;
  }

  // ==================== PERSONS (CONTACTS) ====================

  /// Add a new person
  Future<String> addPerson(PersonModel person) async {
    final docRef = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.personsCollection)
        .add(person.toJson());
    return docRef.id;
  }

  /// Update a person
  Future<void> updatePerson(PersonModel person) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.personsCollection)
        .doc(person.id)
        .update(person.toJson());
  }

  /// Delete a person
  Future<void> deletePerson(String personId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.personsCollection)
        .doc(personId)
        .delete();
  }

  /// Get all persons
  Future<List<PersonModel>> getPersons() async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.personsCollection)
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return PersonModel.fromJson(data);
    }).toList();
  }

  /// Stream persons
  Stream<List<PersonModel>> streamPersons() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.personsCollection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return PersonModel.fromJson(data);
            }).toList());
  }

  // ==================== SETTLEMENTS ====================

  /// Add a settlement
  Future<String> addSettlement(SettlementModel settlement) async {
    final docRef = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.settlementsCollection)
        .add(settlement.toJson());
    return docRef.id;
  }

  /// Get settlements with a person
  Future<List<SettlementModel>> getSettlementsWithPerson(String personId) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.settlementsCollection)
        .where('personId', isEqualTo: personId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return SettlementModel.fromJson(data);
    }).toList();
  }

  /// Stream all settlements
  Stream<List<SettlementModel>> streamSettlements() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.settlementsCollection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return SettlementModel.fromJson(data);
            }).toList());
  }

  // ==================== BALANCE CALCULATIONS ====================

  /// Calculate balances with all persons from transactions and settlements
  Future<List<PersonBalanceModel>> calculatePersonBalances() async {
    final Map<String, PersonBalanceModel> balances = {};

    // Get all persons first
    final persons = await getPersons();
    for (final person in persons) {
      balances[person.id] = PersonBalanceModel(
        personId: person.id,
        personName: person.name,
        balance: 0,
        transactionCount: 0,
      );
    }

    // Get all split transactions
    final transactionsSnapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.transactionsCollection)
        .where('isSplit', isEqualTo: true)
        .get();

    for (final doc in transactionsSnapshot.docs) {
      final data = doc.data();
      final totalAmount = (data['amount'] as num).toDouble();
      final paidByPersonId = data['paidByPersonId'] as String?;
      final splits = (data['splits'] as List<dynamic>?) ?? [];

      // Process each split
      for (final splitData in splits) {
        final personId = splitData['personId'] as String?;
        if (personId == null) continue; // Skip "Me" entries

        final splitAmount = (splitData['amount'] as num).toDouble();

        // Initialize balance if person not yet in map
        if (!balances.containsKey(personId)) {
          balances[personId] = PersonBalanceModel(
            personId: personId,
            personName: splitData['personName'] as String? ?? 'Unknown',
            balance: 0,
            transactionCount: 0,
          );
        }

        final currentBalance = balances[personId]!;

        if (paidByPersonId == null) {
          // I paid, so they owe me their share
          balances[personId] = currentBalance.copyWith(
            balance: currentBalance.balance + splitAmount,
            transactionCount: currentBalance.transactionCount + 1,
          );
        } else if (paidByPersonId == personId) {
          // This person paid, so I owe them my share
          final myShare = (data['myShare'] as num?)?.toDouble() ?? 0;
          balances[personId] = currentBalance.copyWith(
            balance: currentBalance.balance - myShare,
            transactionCount: currentBalance.transactionCount + 1,
          );
        }
      }
    }

    // Subtract settlements
    final settlementsSnapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.settlementsCollection)
        .get();

    for (final doc in settlementsSnapshot.docs) {
      final data = doc.data();
      final personId = data['personId'] as String;
      final amount = (data['amount'] as num).toDouble();
      final settledByMe = data['settledByMe'] as bool? ?? true;

      if (balances.containsKey(personId)) {
        final currentBalance = balances[personId]!;
        // If I settled (paid them), reduce what they owe me (or increase what I owe them)
        // If they settled (paid me), increase what they owe me (or reduce what I owe them)
        final adjustment = settledByMe ? -amount : amount;
        balances[personId] = currentBalance.copyWith(
          balance: currentBalance.balance + adjustment,
        );
      }
    }

    // Filter out zero balances and return sorted list
    return balances.values
        .where((b) => b.balance.abs() > 0.01 || b.transactionCount > 0)
        .toList()
      ..sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));
  }

  /// Get split transactions with a specific person
  Future<List<TransactionModel>> getSplitTransactionsWithPerson(String personId) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection(AppConstants.transactionsCollection)
        .where('isSplit', isEqualTo: true)
        .orderBy('date', descending: true)
        .get();

    final transactions = <TransactionModel>[];
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      
      final splits = (data['splits'] as List<dynamic>?) ?? [];
      final involvesPerson = splits.any((s) => s['personId'] == personId) ||
          data['paidByPersonId'] == personId;
      
      if (involvesPerson) {
        transactions.add(TransactionModel.fromJson(data));
      }
    }
    
    return transactions;
  }
}
