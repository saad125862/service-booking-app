import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seba_app/features/auth/domain/user.dart';
import 'package:seba_app/features/auth/presentation/auth_controller.dart';
import 'package:seba_app/features/auth/presentation/login_screen.dart';

/// Records login attempts instead of calling the API.
class RecordingAuth extends AuthController {
  static final List<({String email, String password})> logins = [];

  @override
  Future<User?> build() async => null;

  @override
  Future<void> login({required String email, required String password}) async {
    logins.add((email: email, password: password));
  }
}

Widget _app() => ProviderScope(
      overrides: [authProvider.overrideWith(RecordingAuth.new)],
      child: const MaterialApp(home: LoginScreen()),
    );

void main() {
  setUp(RecordingAuth.logins.clear);

  testWidgets('shows the login form with both quick sign-in buttons', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.text('Quick sign in (demo)'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Customer'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Admin'), findsOneWidget);
  });

  testWidgets('validates empty fields before calling the API', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(RecordingAuth.logins, isEmpty);
  });

  testWidgets('rejects a malformed email', (tester) async {
    await tester.pumpWidget(_app());

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'x');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(RecordingAuth.logins, isEmpty);
  });

  testWidgets('the Customer quick button signs in as the demo customer', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.widgetWithText(OutlinedButton, 'Customer'));
    await tester.pumpAndSettle();

    expect(RecordingAuth.logins, [(email: 'demo@example.com', password: 'Demo@1234')]);
  });

  testWidgets('the Admin quick button signs in as the demo admin', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.widgetWithText(OutlinedButton, 'Admin'));
    await tester.pumpAndSettle();

    expect(RecordingAuth.logins, [(email: 'admin@example.com', password: 'Admin@1234')]);
  });
}
