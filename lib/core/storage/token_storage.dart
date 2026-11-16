import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT so the session survives app restarts.
/// Uses the platform keystore (Android Keystore) via flutter_secure_storage.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'seba_auth_token';
  final FlutterSecureStorage _storage;
  String? _cached;
  bool _loaded = false;

  Future<String?> read() async {
    if (_loaded) return _cached;
    try {
      _cached = await _storage.read(key: _key);
    } catch (_) {
      // Storage can be unavailable (e.g. blocked browser storage): behave as signed out.
      _cached = null;
    }
    _loaded = true;
    return _cached;
  }

  Future<void> write(String token) async {
    _cached = token;
    _loaded = true;
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {
      // Keep the in-memory token so the current session still works.
    }
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
