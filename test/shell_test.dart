import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seba_app/core/theme/theme_controller.dart';
import 'package:seba_app/features/auth/domain/user.dart';
import 'package:seba_app/features/auth/presentation/auth_controller.dart';
import 'package:seba_app/features/notifications/presentation/notification_providers.dart';
import 'package:seba_app/features/shell/nav_item.dart';
import 'package:seba_app/features/shell/responsive_shell.dart';
import 'package:seba_app/features/shell/shell_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

const _customer = User(id: '1', name: 'Demo User', email: 'demo@example.com');
const _admin = User(id: '2', name: 'Admin User', email: 'admin@example.com', role: 'admin');

class SignedInAuth extends AuthController {
  SignedInAuth(this.user);
  final User user;
  static int logouts = 0;

  @override
  Future<User?> build() async => user;

  @override
  Future<void> logout() async {
    logouts++;
    state = const AsyncData(null);
  }
}

Widget _app(User user, {int unread = 0}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => ResponsiveShell(
          bottomItems: customerNav,
          currentIndex: 0,
          onSelect: (_) {},
          body: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Home'), leading: shellMenuLeading(context)),
              body: const Center(child: Text('content')),
            ),
          ),
        ),
      ),
      GoRoute(path: '/notifications', builder: (_, _) => const Text('notifications page')),
      GoRoute(path: '/bookings', builder: (_, _) => const Text('bookings page')),
    ],
  );
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => SignedInAuth(user)),
      unreadCountProvider.overrideWith(() => FixedUnread(unread)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    SignedInAuth.logouts = 0;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('phones: bottom navigation plus a menu button that opens the sidebar drawer', (tester) async {
    _size(tester, const Size(400, 800));
    await tester.pumpWidget(_app(_customer, unread: 3));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byTooltip('Menu'), findsOneWidget);
    expect(find.text('demo@example.com'), findsNothing); // sidebar closed

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    expect(find.text('Demo User'), findsOneWidget);
    expect(find.text('demo@example.com'), findsOneWidget);
    for (final label in ['Home', 'My bookings', 'Assistant', 'Profile', 'Notifications', 'Sign out']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('3'), findsOneWidget); // unread badge
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('wide screens: a permanent sidebar, no drawer button and no bottom bar', (tester) async {
    _size(tester, const Size(1200, 800));
    await tester.pumpWidget(_app(_customer));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byTooltip('Menu'), findsNothing);
    expect(find.text('demo@example.com'), findsOneWidget); // sidebar is always visible
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('admins see the admin navigation and an Admin badge', (tester) async {
    _size(tester, const Size(1200, 800));
    await tester.pumpWidget(_app(_admin));
    await tester.pumpAndSettle();

    expect(find.text('Admin'), findsOneWidget);
    for (final label in [
      'Dashboard',
      'Bookings',
      'Services',
      'Discount requests',
      'Sales reports',
      'Payment options',
      'Custom fields',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('My bookings'), findsNothing);
  });

  testWidgets('sign out asks for confirmation and then signs the user out', (tester) async {
    _size(tester, const Size(1200, 800));
    await tester.pumpWidget(_app(_customer));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.text('Stay signed in'));
    await tester.pumpAndSettle();
    expect(SignedInAuth.logouts, 0);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(SignedInAuth.logouts, 1);
  });

  testWidgets('phones: Sign out in the sidebar drawer confirms and signs out (the drawer closes with it)', (tester) async {
    _size(tester, const Size(400, 800));
    await tester.pumpWidget(_app(_customer));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    // Backing out keeps the user signed in.
    await tester.tap(find.text('Stay signed in'));
    await tester.pumpAndSettle();
    expect(SignedInAuth.logouts, 0);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(SignedInAuth.logouts, 1);
    expect(find.text('Sign out?'), findsNothing);
  });

  testWidgets('the sidebar opens the notifications page', (tester) async {
    _size(tester, const Size(1200, 800));
    await tester.pumpWidget(_app(_customer));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('notifications page'), findsOneWidget);
  });

  group('dark / light mode', () {
    testWidgets('the selector changes the theme mode and remembers it', (tester) async {
      _size(tester, const Size(1200, 800));
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => SignedInAuth(_customer)),
          unreadCountProvider.overrideWith(FixedUnread.new),
        ],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                ResponsiveShell(bottomItems: customerNav, currentIndex: 0, onSelect: (_) {}, body: const SizedBox()),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // New installs start in the dark premium look.
      expect(container.read(themeModeProvider), ThemeMode.dark);
      await tester.tap(find.byTooltip('Light mode'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('seba_theme_mode'), 'light');

      await tester.tap(find.byTooltip('Dark mode'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('a saved choice is restored on the next launch', () async {
      SharedPreferences.setMockInitialValues({'seba_theme_mode': 'light'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider); // starts loading
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
