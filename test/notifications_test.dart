import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seba_app/core/network/api_client.dart';
import 'package:seba_app/core/network/api_exception.dart';
import 'package:seba_app/core/storage/token_storage.dart';
import 'package:seba_app/core/utils/formatters.dart';
import 'package:seba_app/features/auth/domain/user.dart';
import 'package:seba_app/features/auth/presentation/auth_controller.dart';
import 'package:seba_app/features/notifications/data/notification_repository.dart';
import 'package:seba_app/features/notifications/domain/app_notification.dart';
import 'package:seba_app/features/notifications/presentation/notification_providers.dart';
import 'package:seba_app/features/notifications/presentation/notifications_screen.dart';

import 'test_helpers.dart';

AppNotification _n(String id, String type, {bool read = false, String? appointmentId, String? discountId}) => AppNotification(
      id: id,
      type: type,
      title: 'Title $id',
      body: 'Body $id',
      isRead: read,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      appointmentId: appointmentId,
      discountRequestId: discountId,
    );

class FakeNotificationRepository extends NotificationRepository {
  FakeNotificationRepository(this.items, {this.fail = false})
      : super(ApiClient(tokenStorage: TokenStorage(), onUnauthorized: () {}));

  List<AppNotification> items;
  final bool fail;
  final List<String> read = [];
  var markAllCalls = 0;

  @override
  Future<List<AppNotification>> list({int limit = 50}) async {
    if (fail) throw const ApiException(message: 'Server unavailable', code: 'NETWORK');
    return items;
  }

  @override
  Future<void> markRead(String id) async {
    read.add(id);
    items = [for (final n in items) n.id == id ? n.copyWith(isRead: true) : n];
  }

  @override
  Future<void> markAllRead() async {
    markAllCalls++;
    items = [for (final n in items) n.copyWith(isRead: true)];
  }
}

class _Auth extends AuthController {
  @override
  Future<User?> build() async => const User(id: '1', name: 'Demo', email: 'd@e.co');
}

Widget _app(FakeNotificationRepository repo) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => const NotificationsScreen()),
    GoRoute(path: '/booking/:id', builder: (_, s) => Text('booking ${s.pathParameters['id']}')),
    GoRoute(path: '/assistant', builder: (_, _) => const Text('assistant page')),
  ]);
  return ProviderScope(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(repo),
      authProvider.overrideWith(_Auth.new),
      unreadCountProvider.overrideWith(FixedUnread.new),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('model and helpers', () {
    test('parses ids from the data payload', () {
      final n = AppNotification.fromJson({
        'id': 'n1',
        'type': 'booking_confirmed',
        'title': 'Booking confirmed',
        'body': 'Good news!',
        'isRead': false,
        'createdAt': '2026-11-16T10:00:00.000Z',
        'data': {'appointmentId': 'a1'},
      });
      expect(n.appointmentId, 'a1');
      expect(n.isRead, isFalse);
      expect(n.icon, Icons.check_circle_outline);
    });

    test('routes a tap to the right place for each role', () {
      expect(routeForNotification(_n('1', 'booking_confirmed', appointmentId: 'a1'), isAdmin: false), '/booking/a1');
      expect(routeForNotification(_n('2', 'booking_new', appointmentId: 'a2'), isAdmin: true), '/admin/bookings/a2');
      expect(routeForNotification(_n('3', 'discount_approved', discountId: 'd1'), isAdmin: false), '/assistant');
      expect(routeForNotification(_n('4', 'discount_request', discountId: 'd1'), isAdmin: true), '/admin/discounts');
      expect(routeForNotification(_n('5', 'other'), isAdmin: false), isNull);
    });

    test('timeAgo is friendly', () {
      final now = DateTime(2026, 11, 16, 12);
      expect(Formatters.timeAgo(now.subtract(const Duration(seconds: 20)), now: now), 'just now');
      expect(Formatters.timeAgo(now.subtract(const Duration(minutes: 5)), now: now), '5 min ago');
      expect(Formatters.timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3 h ago');
      expect(Formatters.timeAgo(now.subtract(const Duration(days: 1)), now: now), '1 day ago');
      expect(Formatters.timeAgo(now.subtract(const Duration(days: 30)), now: now), 'Oct 17, 2026');
    });
  });

  group('notifications screen', () {
    testWidgets('lists notifications and marks one as read when opened', (tester) async {
      final repo = FakeNotificationRepository([
        _n('1', 'booking_confirmed', appointmentId: 'a1'),
        _n('2', 'payment_verified', read: true),
      ]);
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      expect(find.text('Title 1'), findsOneWidget);
      expect(find.text('Title 2'), findsOneWidget);
      expect(find.textContaining('5 min ago'), findsNWidgets(2));
      expect(find.text('Mark all read'), findsOneWidget);

      await tester.tap(find.text('Title 1'));
      await tester.pumpAndSettle();
      expect(repo.read, ['1']);
      expect(find.text('booking a1'), findsOneWidget); // opened the booking
    });

    testWidgets('mark all read clears the unread state', (tester) async {
      final repo = FakeNotificationRepository([_n('1', 'booking_created'), _n('2', 'booking_confirmed')]);
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(repo.markAllCalls, 1);
      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('shows an empty state', (tester) async {
      await tester.pumpWidget(_app(FakeNotificationRepository([])));
      await tester.pumpAndSettle();
      expect(find.text('No notifications yet'), findsOneWidget);
    });

    testWidgets('shows an error with retry', (tester) async {
      await tester.pumpWidget(_app(FakeNotificationRepository([], fail: true)));
      await tester.pumpAndSettle();
      expect(find.text('Server unavailable'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
