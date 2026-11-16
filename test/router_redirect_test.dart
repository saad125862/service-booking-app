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
      expect(appRedirect(const AsyncLoading(), '/'), '/splash?from=%2F');
      expect(appRedirect(const AsyncLoading(), '/splash'), isNull);
      expect(
        appRedirect(AsyncError(const ApiException(message: 'offline'), StackTrace.empty), '/login'),
        '/splash?from=%2Flogin',
      );
    });

    test('remembers the page being opened and returns there after the session is restored', () {
      expect(
        appRedirect(const AsyncLoading(), '/service/abc/book'),
        '/splash?from=%2Fservice%2Fabc%2Fbook',
      );
      expect(appRedirect(_signedIn(_customer), '/splash', from: '/service/abc/book'), '/service/abc/book');
      expect(appRedirect(_signedIn(_customer), '/splash', from: '/bookings'), '/bookings');
    });

    test('ignores unsafe or forbidden remembered locations', () {
      expect(appRedirect(_signedIn(_customer), '/splash', from: '/admin'), '/');
      expect(appRedirect(_signedIn(_admin), '/splash', from: '/bookings'), '/admin');
      expect(appRedirect(_signedIn(_customer), '/splash', from: '//evil.example'), '/');
      expect(appRedirect(_signedIn(_customer), '/splash', from: '/login'), '/');
      expect(appRedirect(_signedIn(_customer), '/splash', from: 'https://evil.example'), '/');
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
