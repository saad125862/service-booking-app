import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seba_app/features/auth/presentation/login_screen.dart';

Widget _app() => const ProviderScope(child: MaterialApp(home: LoginScreen()));

void main() {
  testWidgets('shows the login form with the demo shortcut', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.text('Use the demo account'), findsOneWidget);
  });

  testWidgets('validates empty fields before calling the API', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('rejects a malformed email', (tester) async {
    await tester.pumpWidget(_app());

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'x');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('the demo shortcut fills in the demo credentials', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.text('Use the demo account'));
    await tester.pump();

    expect(find.text('demo@example.com'), findsOneWidget);
  });
}
