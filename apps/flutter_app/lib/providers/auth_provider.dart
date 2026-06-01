import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api/api_client.dart';
import '../core/api/api_provider.dart';

enum AuthStatus { unknown, authenticated, guest }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? userType;
  final String? token;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.userType,
    this.token,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? userType,
    String? token,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._api) : super(const AuthState());

  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
      );
    } else {
      state = const AuthState(status: AuthStatus.guest);
    }
  }

  Future<void> login(String email, String password) async {
    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = response.data['token'] as String;
    await _storage.write(key: 'jwt_token', value: token);
    state = AuthState(
      status: AuthStatus.authenticated,
      token: token,
      userId: response.data['user']['id'],
      userType: response.data['user']['type'],
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    state = const AuthState(status: AuthStatus.guest);
  }

  void continueAsGuest() {
    state = const AuthState(status: AuthStatus.guest);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(api);
});
