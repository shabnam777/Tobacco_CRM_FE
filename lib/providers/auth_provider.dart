import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String error;
  final Map<String, dynamic>? user;
  const AuthState({this.status = AuthStatus.initial, this.error = '', this.user});
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  AuthState copyWith({AuthStatus? status, String? error, Map<String, dynamic>? user}) =>
      AuthState(status: status ?? this.status, error: error ?? this.error, user: user ?? this.user);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final token = StorageService.getToken();
    if (token != null) return AuthState(status: AuthStatus.authenticated, user: StorageService.getUser());
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: '');
    try {
      final res = await ApiService.login(email, password);
      await StorageService.saveToken(res['access_token'] ?? '');
      await StorageService.saveUser(Map<String, dynamic>.from(res['user'] ?? {'email': email, 'name': 'Export Manager'}));
      state = state.copyWith(status: AuthStatus.authenticated, user: StorageService.getUser());
      return true;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.toString().replaceAll('ApiException: ', ''));
      return false;
    }
  }

  Future<void> loginOffline() async {
    await StorageService.saveToken('offline_mode_token');
    await StorageService.saveUser({'email': 'demo@tobaccocrm.in', 'name': 'Export Manager (Offline)'});
    state = state.copyWith(status: AuthStatus.authenticated, user: StorageService.getUser());
  }

  Future<void> logout() async {
    await StorageService.clearToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() => state = state.copyWith(error: '');
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
