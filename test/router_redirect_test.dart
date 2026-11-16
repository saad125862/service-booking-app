import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seba_app/core/network/api_exception.dart';
import 'package:seba_app/core/router/app_router.dart';
import 'package:seba_app/features/auth/domain/user.dart';

const _customer = User(id: '1', name: 'Demo User', email: 'demo@example.com');
const _admin = User(id: '2', name: 'Admin User', email: 'admin@example.com', role: 'admin');

AsyncValue<User?> _signedIn(User user) => AsyncData(user);
const AsyncValue<User?> _signedOut = AsyncData(null);

void main() {
  group('appRedirect', () {
    test('shows the splash while the saved session is restored, and when that fails', () {
      expect(appRedirect(const AsyncLoading(), '/'), '/splash');
      expect(appRedirect(const AsyncLoading(), '/splash'), isNull);
      expect(
        appRedirect(AsyncError(const ApiException(message: 'offline'), StackTrace.empty), '/login'),
        '/splash',
      );
    });

    test('signed-out users can only see login and register', () {
      expect(appRedirect(_signedOut, '/'), '/login');
      expect(appRedirect(_signedOut, '/bookings'), '/login');
      expect(appRedirect(_signedOut, '/admin'), '/login');
      expect(appRedirect(_signedOut, '/login'), isNull);
      expect(appRedirect(_signedOut, '/register'), isNull);
    });

    test('customers land on the tabs and cannot open the admin area', () {
      expect(appRedirect(_signedIn(_customer), '/splash'), '/');
      expect(appRedirect(_signedIn(_customer), '/login'), '/');
      expect(appRedirect(_signedIn(_customer), '/bookings'), isNull);
      expect(appRedirect(_signedIn(_customer), '/service/abc'), isNull);
      expect(appRedirect(_signedIn(_customer), '/admin'), '/');
    });

    test('admins land on the admin area and stay inside it', () {
      expect(appRedirect(_signedIn(_admin), '/splash'), '/admin');
      expect(appRedirect(_signedIn(_admin), '/login'), '/admin');
      expect(appRedirect(_signedIn(_admin), '/'), '/admin');
      expect(appRedirect(_signedIn(_admin), '/admin'), isNull);
    });
  });

  group('User role', () {
    test('parses the role from the API and defaults to a customer', () {
      final admin = User.fromJson({'id': '2', 'name': 'A', 'email': 'a@b.co', 'role': 'admin'});
      expect(admin.isAdmin, isTrue);
      final legacy = User.fromJson({'id': '1', 'name': 'B', 'email': 'b@b.co'});
      expect(legacy.isAdmin, isFalse);
    });
  });
}
