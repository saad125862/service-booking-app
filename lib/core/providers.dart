import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/api_client.dart';
import 'storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Bumped whenever the API answers 401 on a protected call (expired/invalid token).
/// The auth controller listens to it and signs the user out, which keeps `core`
/// independent from the auth feature.
class SessionExpiry extends Notifier<int> {
  @override
  int build() => 0;
  void notify() => state++;
}

final sessionExpiryProvider = NotifierProvider<SessionExpiry, int>(SessionExpiry.new);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: () => ref.read(sessionExpiryProvider.notifier).notify(),
  );
});
