import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seba_app/core/network/api_exception.dart';
import 'package:seba_app/features/auth/domain/user.dart';
import 'package:seba_app/features/auth/presentation/auth_controller.dart';
import 'package:seba_app/features/notifications/presentation/notification_providers.dart';
import 'package:seba_app/features/profile/presentation/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

class ProfileAuth extends AuthController {
  ProfileAuth(this.user, {this.passwordError});

  final User user;
  final ApiException? passwordError;
  static final List<Map<String, String?>> updates = [];
  static final List<Map<String, String>> passwordChanges = [];

  @override
  Future<User?> build() async => user;

  @override
  Future<void> updateProfile({String? name, String? phone, String? address}) async {
    updates.add({'name': name, 'phone': phone, 'address': address});
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    if (passwordError != null) throw passwordError!;
    passwordChanges.add({'current': currentPassword, 'new': newPassword});
  }
}

const _customer = User(
  id: '1',
  name: 'Demo User',
  email: 'demo@example.com',
  phone: '+880 1700 000000',
  address: 'House 12, Road 5, Dhanmondi, Dhaka',
);
const _admin = User(id: '2', name: 'Admin User', email: 'admin@example.com', role: 'admin');

Widget _app(User user, {ApiException? passwordError}) {
  final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => const ProfileScreen())]);
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => ProfileAuth(user, passwordError: passwordError)),
      unreadCountProvider.overrideWith(FixedUnread.new),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    ProfileAuth.updates.clear();
    ProfileAuth.passwordChanges.clear();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the saved details, including the default address', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_customer));
    await tester.pumpAndSettle();

    expect(find.text('demo@example.com'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Full name'), findsOneWidget);
    expect(find.text('Demo User'), findsOneWidget);
    expect(find.text('+880 1700 000000'), findsOneWidget);
    expect(find.text('House 12, Road 5, Dhanmondi, Dhaka'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('saving sends the edited name, phone and address', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_customer));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Rahim Uddin');
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone (optional)'), '');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(ProfileAuth.updates, [
      {'name': 'Rahim Uddin', 'phone': '', 'address': 'House 12, Road 5, Dhanmondi, Dhaka'},
    ]);
    expect(find.text('Profile updated'), findsOneWidget);
  });

  testWidgets('validates the details before saving', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_customer));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'A');
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone (optional)'), 'abc');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(ProfileAuth.updates, isEmpty);
  });

  testWidgets('changing the password checks the rules and the confirmation', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_customer));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Current password'), 'Demo@1234');
    await tester.enterText(find.widgetWithText(TextFormField, 'New password'), 'short');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm new password'), 'different');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Change password'));
    await tester.pumpAndSettle();
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(ProfileAuth.passwordChanges, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'New password'), 'NewPass123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm new password'), 'NewPass123');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Change password'));
    await tester.pumpAndSettle();

    expect(ProfileAuth.passwordChanges, [
      {'current': 'Demo@1234', 'new': 'NewPass123'},
    ]);
    expect(find.text('Password changed'), findsOneWidget);
  });

  testWidgets('a wrong current password shows the reason', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(
      _customer,
      passwordError: const ApiException(message: 'Current password is incorrect', code: 'INVALID_CURRENT_PASSWORD', statusCode: 400),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Current password'), 'wrong');
    await tester.enterText(find.widgetWithText(TextFormField, 'New password'), 'NewPass123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm new password'), 'NewPass123');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Change password'));
    await tester.pumpAndSettle();

    expect(find.text('Current password is incorrect'), findsOneWidget);
  });

  testWidgets('admins get the same screen without the service address field', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_admin));
    await tester.pumpAndSettle();

    expect(find.text('Admin account'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Default service address (optional)'), findsNothing);
  });
}
