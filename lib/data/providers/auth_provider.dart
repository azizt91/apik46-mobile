import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';

final authControllerProvider = Provider<AuthController>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(ref, authRepository);
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<String?>>((ref) {
  return AuthStateNotifier();
});

class AuthController {
  final Ref _ref;
  final AuthRepository _authRepository;

  AuthController(this._ref, this._authRepository);

  Future<void> login({required String email, required String password}) async {
    final stateNotifier = _ref.read(authStateProvider.notifier);
    stateNotifier.setLoading();

    try {
      final data = await _authRepository.login(email, password);
      final token = data['token'];
      
      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      
      // Update state
      stateNotifier.setAuthenticated(token);
    } catch (e) {
      // Don't set global state to error, just rethrow for UI to handle
      // stateNotifier.setError(e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    final stateNotifier = _ref.read(authStateProvider.notifier);
    final token = stateNotifier.state.value;
    
    if (token != null) {
      await _authRepository.logout(token);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    
    stateNotifier.setUnauthenticated();
  }
}

class AuthStateNotifier extends StateNotifier<AsyncValue<String?>> {
  AuthStateNotifier() : super(const AsyncValue.data(null)) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      state = AsyncValue.data(token);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  void setLoading() {
    state = const AsyncValue.loading();
  }

  void setAuthenticated(String token) {
    state = AsyncValue.data(token);
  }

  void setUnauthenticated() {
    state = const AsyncValue.data(null);
  }

  void setError(String message) {
    state = AsyncValue.error(message, StackTrace.current);
  }
}
