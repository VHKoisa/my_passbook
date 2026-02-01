import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../../shared/models/models.dart';

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

/// Transactions stream provider
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(firestoreServiceProvider).streamTransactions();
});

/// Recent transactions provider (last 5)
final recentTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(firestoreServiceProvider).streamTransactions(limit: 5);
});

/// Categories stream provider
final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(firestoreServiceProvider).streamCategories();
});

/// Expense categories provider
final expenseCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(firestoreServiceProvider).streamCategories(type: TransactionType.expense);
});

/// Income categories provider
final incomeCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(firestoreServiceProvider).streamCategories(type: TransactionType.income);
});

/// Budgets stream provider
final budgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(firestoreServiceProvider).streamBudgets();
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
