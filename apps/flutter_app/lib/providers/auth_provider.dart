import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api/api_client.dart';
import '../core/api/api_provider.dart';

enum AuthStatus { unknown, authenticated, guest }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? userType;
  final String? userName;
  final String? token;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.userType,
    this.userName,
    this.token,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? userType,
    String? userName,
    String? token,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      userName: userName ?? this.userName,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._api) : super(const AuthState());

  /// Called on app start — restores session from secure storage.
  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      final userId = await _storage.read(key: 'user_id');
      final userType = await _storage.read(key: 'user_type');
      final userName = await _storage.read(key: 'user_name');
      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        userId: userId,
        userType: userType,
        userName: userName,
      );
    } else {
      state = const AuthState(status: AuthStatus.guest);
    }
  }

  Future<void> login(String email, String password) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    await _persistSession(response.data!);
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String type, // 'consumer' | 'trader'
    required String language,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'type': type,
        'language': language,
      },
    );
    await _persistSession(response.data!);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState(status: AuthStatus.guest);
  }

  void continueAsGuest() {
    state = const AuthState(status: AuthStatus.guest);
  }

  /// Update local display name (after profile edit).
  Future<void> updateLocalName(String name) async {
    await _storage.write(key: 'user_name', value: name);
    state = state.copyWith(userName: name);
  }

  // ── helpers ─────────────────────────────────────────────────────────────

  Future<void> _persistSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    await Future.wait([
      _storage.write(key: 'jwt_token', value: token),
      _storage.write(key: 'user_id', value: user['id'] as String),
      _storage.write(key: 'user_type', value: user['type'] as String),
      _storage.write(key: 'user_name', value: user['name'] as String),
    ]);
    state = AuthState(
      status: AuthStatus.authenticated,
      token: token,
      userId: user['id'] as String,
      userType: user['type'] as String,
      userName: user['name'] as String,
    );
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(api);
});
