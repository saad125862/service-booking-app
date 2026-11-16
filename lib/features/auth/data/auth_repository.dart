import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/user.dart';

/// Talks to /auth and /users/me and owns the persisted token.
class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<User> login({required String email, required String password}) async {
    final res = await _api.post('/auth/login', data: {'email': email.trim(), 'password': password});
    return _handleAuthResponse(res);
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.post(
      '/auth/register',
      data: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );
    return _handleAuthResponse(res);
  }

  /// Restores a saved session. Returns null when signed out or the token is no
  /// longer valid; rethrows network errors so the UI can offer a retry instead
  /// of silently logging the user out while offline.
  Future<User?> restoreSession() async {
    final token = await _tokens.read();
    if (token == null) return null;
    try {
      final res = await _api.get('/users/me');
      return User.fromJson(res.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _tokens.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<User> updateProfile({String? name, String? phone, String? address}) async {
    final res = await _api.patch('/users/me', data: {
      if (name != null) 'name': name.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (address != null) 'address': address.trim(),
    });
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _api.patch('/users/me/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> logout() => _tokens.clear();

  Future<User> _handleAuthResponse(ApiResponse res) async {
    final data = res.data as Map<String, dynamic>;
    await _tokens.write(data['token'] as String);
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }
}
