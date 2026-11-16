import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider));
});

/// Holds the signed-in [User] (or null). Loading on app start while the saved
/// session is checked, which is what makes the login persistent.
class AuthController extends AsyncNotifier<User?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<User?> build() {
    // A 401 on any protected call means the token expired: sign out.
    ref.listen(sessionExpiryProvider, (_, _) => _expire());
    return _repo.restoreSession();
  }

  Future<void> login({required String email, required String password}) async {
    final user = await _repo.login(email: email, password: password);
    state = AsyncData(user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = await _repo.register(name: name, email: email, password: password);
    state = AsyncData(user);
  }

  Future<void> updateProfile({String? name, String? phone, String? address}) async {
    final user = await _repo.updateProfile(name: name, phone: phone, address: address);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }

  Future<void> _expire() async {
    if (state.value == null) return;
    await _repo.logout();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthController, User?>(AuthController.new);
