import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../../shared/models/models.dart';
import '../../main.dart' show localStorageServiceProvider;

// ==================== SERVICE PROVIDERS ====================

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// ==================== AUTH PROVIDERS ====================

/// Auth state provider - listens to Firebase auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

// ==================== AUTH NOTIFIER ====================

/// Auth state for the notifier
class AuthState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Auth notifier for handling auth actions
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthNotifier(this._authService, this._firestoreService) : super(const AuthState());

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: name,
      );

      // Create user document in Firestore
      if (credential.user != null) {
        final user = UserModel(
          id: credential.user!.uid,
          email: email,
          displayName: name,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestoreService.saveUser(user);

        // Initialize default categories
        await _firestoreService.initializeDefaultCategories(credential.user!.uid);
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _authService.signInWithGoogle();

      // Create/update user document in Firestore
      if (credential.user != null) {
        final existingUser = await _firestoreService.getUser(credential.user!.uid);
        
        if (existingUser == null) {
          // New user - create document and initialize categories
          final user = UserModel(
            id: credential.user!.uid,
            email: credential.user!.email ?? '',
            displayName: credential.user!.displayName,
            photoUrl: credential.user!.photoURL,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _firestoreService.saveUser(user);
          await _firestoreService.initializeDefaultCategories(credential.user!.uid);
        }
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _authService.signInWithApple();

      // Create/update user document in Firestore
      if (credential.user != null) {
        final existingUser = await _firestoreService.getUser(credential.user!.uid);
        
        if (existingUser == null) {
          // New user - create document and initialize categories
          final user = UserModel(
            id: credential.user!.uid,
            email: credential.user!.email ?? '',
            displayName: credential.user!.displayName,
            photoUrl: credential.user!.photoURL,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _firestoreService.saveUser(user);
          await _firestoreService.initializeDefaultCategories(credential.user!.uid);
        }
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signOut();
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
    state = const AuthState();
  }
}

/// Auth notifier provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(firestoreServiceProvider),
  );
});

// ==================== DATA PROVIDERS ====================

/// Transactions stream provider with offline fallback
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final firestoreStream = ref.watch(firestoreServiceProvider).streamTransactions();
  final localStorage = ref.watch(localStorageServiceProvider);
  
  // Cache data when received from Firestore
  return firestoreStream.map((transactions) {
    localStorage.cacheTransactions(user.uid, transactions);
    return transactions;
  }).handleError((error) {
    // Return cached data on error (offline)
    return localStorage.getCachedTransactions(user.uid);
  });
});

/// Recent transactions provider (last 5) with offline fallback
final recentTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final firestoreStream = ref.watch(firestoreServiceProvider).streamTransactions(limit: 5);
  final localStorage = ref.watch(localStorageServiceProvider);
  
  return firestoreStream.handleError((error) {
    return localStorage.getCachedTransactions(user.uid).take(5).toList();
  });
});

/// Categories stream provider with offline fallback
final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final firestoreStream = ref.watch(firestoreServiceProvider).streamCategories();
  final localStorage = ref.watch(localStorageServiceProvider);
  
  return firestoreStream.map((categories) {
    localStorage.cacheCategories(user.uid, categories);
    return categories;
  }).handleError((error) {
    return localStorage.getCachedCategories(user.uid);
  });
});

/// Expense categories provider with offline fallback
final expenseCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final firestoreStream = ref.watch(firestoreServiceProvider).streamCategories(type: TransactionType.expense);
  final localStorage = ref.watch(localStorageServiceProvider);
  
  return firestoreStream.handleError((error) {
    return localStorage.getCachedCategories(user.uid, type: TransactionType.expense);
  });
});

/// Income categories provider with offline fallback
final incomeCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final firestoreStream = ref.watch(firestoreServiceProvider).streamCategories(type: TransactionType.income);
  final localStorage = ref.watch(localStorageServiceProvider);
  
  return firestoreStream.handleError((error) {
    return localStorage.getCachedCategories(user.uid, type: TransactionType.income);
  });
});

/// Budgets stream provider with offline fallback
final budgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final firestoreStream = ref.watch(firestoreServiceProvider).streamBudgets();
  final localStorage = ref.watch(localStorageServiceProvider);
  
  return firestoreStream.map((budgets) {
    localStorage.cacheBudgets(user.uid, budgets);
    return budgets;
  }).handleError((error) {
    return localStorage.getCachedBudgets(user.uid);
  });
});

/// Current month budget provider
final currentMonthBudgetProvider = FutureProvider<BudgetModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  final now = DateTime.now();
  return ref.watch(firestoreServiceProvider).getBudgetForMonth(now.month, now.year);
});

/// Monthly summary provider
final monthlySummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {'income': 0, 'expense': 0, 'balance': 0};
  
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  
  return ref.watch(firestoreServiceProvider).getTransactionSummary(
    startDate: startOfMonth,
    endDate: endOfMonth,
  );
});

// ==================== PERSONS PROVIDERS ====================

/// Persons stream provider
final personsProvider = StreamProvider<List<PersonModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(firestoreServiceProvider).streamPersons();
});

/// Person balances provider
final personBalancesProvider = FutureProvider<List<PersonBalanceModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return ref.watch(firestoreServiceProvider).calculatePersonBalances();
});

/// Settlements stream provider
final settlementsProvider = StreamProvider<List<SettlementModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(firestoreServiceProvider).streamSettlements();
});

// ==================== PERSONS NOTIFIER ====================

/// State for persons management
class PersonsState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const PersonsState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  PersonsState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return PersonsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Notifier for managing persons
class PersonsNotifier extends StateNotifier<PersonsState> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  PersonsNotifier(this._firestoreService, this._ref) : super(const PersonsState());

  /// Add a new person
  Future<void> addPerson({
    required String name,
    String? phone,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      final person = PersonModel(
        id: '',
        userId: user.uid,
        name: name,
        phone: phone,
        email: email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.addPerson(person);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update a person
  Future<void> updatePerson(PersonModel person) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _firestoreService.updatePerson(person.copyWith(
        updatedAt: DateTime.now(),
      ));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Delete a person
  Future<void> deletePerson(String personId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await _firestoreService.deletePerson(personId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add settlement
  Future<void> addSettlement({
    required String personId,
    required String personName,
    required double amount,
    required bool settledByMe,
    String? note,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      final settlement = SettlementModel(
        id: '',
        userId: user.uid,
        personId: personId,
        personName: personName,
        amount: amount,
        settledByMe: settledByMe,
        note: note,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _firestoreService.addSettlement(settlement);
      _ref.invalidate(personBalancesProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const PersonsState();
  }
}

/// Persons notifier provider
final personsNotifierProvider = StateNotifierProvider<PersonsNotifier, PersonsState>((ref) {
  return PersonsNotifier(
    ref.watch(firestoreServiceProvider),
    ref,
  );
});
