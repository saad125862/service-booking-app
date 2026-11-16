import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seba_app/core/network/api_client.dart';
import 'package:seba_app/core/network/api_exception.dart';
import 'package:seba_app/core/storage/token_storage.dart';
import 'package:seba_app/features/admin/data/admin_repository.dart';
import 'package:seba_app/features/admin/domain/dashboard.dart';
import 'package:seba_app/features/admin/presentation/admin_booking_detail_screen.dart';
import 'package:seba_app/features/admin/presentation/admin_bookings_screen.dart';
import 'package:seba_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:seba_app/features/admin/presentation/admin_providers.dart';
import 'package:seba_app/features/auth/domain/user.dart';
import 'package:seba_app/features/auth/presentation/auth_controller.dart';
import 'package:seba_app/features/booking/domain/appointment.dart';
import 'package:seba_app/features/notifications/presentation/notification_providers.dart';
import 'package:seba_app/features/shell/nav_item.dart';
import 'package:seba_app/features/shell/responsive_shell.dart';
import 'package:seba_app/features/shell/shell_scope.dart';

import 'test_helpers.dart';

Map<String, dynamic> _bookingJson({
  String id = 'b1',
  String status = 'pending',
  String payment = 'submitted',
  String customer = 'Rahim Uddin',
  String service = 'Swedish Massage',
  num price = 2000,
}) =>
    {
      'id': id,
      'status': status,
      'startTime': '2030-01-01T04:00:00.000Z',
      'endTime': '2030-01-01T05:00:00.000Z',
      'startLabel': 'Tue, Jan 1, 2030, 10:00 AM',
      'address': 'House 12, Road 5, Dhanmondi, Dhaka',
      'notes': null,
      'price': price,
      'originalPrice': 2500,
      'discountAmount': 500,
      'paymentStatus': payment,
      'paymentReference': 'TRX12345AB',
      'paymentMethod': {'id': 'pm1', 'code': 'bkash', 'name': 'bKash', 'type': 'mobile_wallet'},
      'service': {'id': 's1', 'name': service, 'price': 2500, 'durationMinutes': 60, 'category': 'Wellness', 'imageUrl': null},
      'customer': {'id': 'c1', 'name': customer, 'email': 'rahim@example.com', 'phone': '+880 1700 000000'},
    };

Map<String, dynamic> _dashboardJson() => {
      'timeZone': 'Asia/Dhaka',
      'totals': {
        'services': 14,
        'customers': 5,
        'bookings': 9,
        'pendingBookings': 3,
        'pendingDiscountRequests': 2,
        'pendingPayments': 1,
      },
      'sales': {
        'today': {'bookings': 1, 'revenue': 2500},
        'thisMonth': {'bookings': 4, 'revenue': 9300},
        'allTime': {'bookings': 6, 'revenue': 15500},
        'pipeline': {'bookings': 3, 'value': 6000},
      },
      'byStatus': {'pending': 3, 'confirmed': 2, 'cancelled': 1, 'completed': 3},
      'topServices': [
        {'serviceId': 's1', 'name': 'Swedish Massage', 'bookings': 3, 'revenue': 7500},
        {'serviceId': 's2', 'name': 'Classic Facial', 'bookings': 2, 'revenue': 3600},
      ],
      'daily': [
        for (var i = 0; i < 14; i++) {'date': '2026-11-${(i + 3).toString().padLeft(2, '0')}', 'bookings': i % 3, 'revenue': (i % 3) * 1800},
      ],
      'recentBookings': [_bookingJson(id: 'b9', status: 'confirmed')],
    };

class FakeAdminRepository extends AdminRepository {
  FakeAdminRepository({this.fail = false, List<Appointment>? bookings})
      : bookings_ = bookings ?? [Appointment.fromJson(_bookingJson())],
        super(ApiClient(tokenStorage: TokenStorage(), onUnauthorized: () {}));

  final bool fail;
  List<Appointment> bookings_;
  final List<Map<String, String?>> queries = [];
  final List<String> statusCalls = [];
  final List<String> paymentCalls = [];

  @override
  Future<DashboardData> dashboard() async {
    if (fail) throw const ApiException(message: 'Server unavailable', code: 'NETWORK');
    return DashboardData.fromJson(_dashboardJson());
  }

  @override
  Future<BookingsPage> bookings({String? status, String? paymentStatus, String? search, int page = 1, int limit = 20}) async {
    queries.add({'status': status, 'paymentStatus': paymentStatus, 'search': search});
    if (fail) throw const ApiException(message: 'Server unavailable', code: 'NETWORK');
    final items = bookings_.where((a) => status == null || a.status.name == status).toList();
    return BookingsPage(items: items, page: 1, totalPages: 1, total: items.length);
  }

  @override
  Future<Appointment> booking(String id) async => bookings_.firstWhere((a) => a.id == id);

  @override
  Future<Appointment> setStatus(String id, String status) async {
    statusCalls.add('$id:$status');
    return bookings_.first;
  }

  @override
  Future<Appointment> setPayment(String id, String status) async {
    paymentCalls.add('$id:$status');
    return bookings_.first;
  }
}

class _AdminAuth extends AuthController {
  @override
  Future<User?> build() async => const User(id: 'a1', name: 'Admin User', email: 'admin@example.com', role: 'admin');
}

Widget _app(FakeAdminRepository repo, Widget home) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => home),
    GoRoute(path: '/admin/bookings', builder: (_, _) => const Text('bookings list page')),
    GoRoute(path: '/admin/bookings/:id', builder: (_, s) => Text('booking ${s.pathParameters['id']}')),
    GoRoute(path: '/admin/discounts', builder: (_, _) => const Text('discounts page')),
  ]);
  return ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(repo),
      authProvider.overrideWith(_AdminAuth.new),
      unreadCountProvider.overrideWith(FixedUnread.new),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('dashboard data', () {
    test('parses sales, totals and what needs attention', () {
      final d = DashboardData.fromJson(_dashboardJson());
      expect(d.today.revenue, 2500);
      expect(d.pipeline.revenue, 6000); // "value" in the API
      expect(d.needsAttention, 3 + 1 + 2);
      expect(d.daily, hasLength(14));
      expect(d.topServices.first.name, 'Swedish Massage');
      expect(d.recentBookings.single.customer?.name, 'Rahim Uddin');
    });
  });

  group('dashboard screen', () {
    testWidgets('shows sales, items needing attention, top services and latest bookings', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(FakeAdminRepository(), const AdminDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sales today'), findsOneWidget);
      expect(find.text('৳2,500'), findsWidgets);
      expect(find.text('৳9,300'), findsOneWidget);
      expect(find.text('৳15,500'), findsOneWidget);
      expect(find.text('৳6,000'), findsOneWidget);
      expect(find.text('3 pending bookings'), findsOneWidget);
      expect(find.text('1 payment to verify'), findsOneWidget);
      expect(find.text('2 discount requests'), findsOneWidget);
      expect(find.text('Top services by revenue'), findsOneWidget);
      expect(find.textContaining('Classic Facial'), findsOneWidget);
      expect(find.text('Rahim Uddin'), findsOneWidget); // latest booking card
    });

    testWidgets('tapping a pending item opens the matching admin screen', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(FakeAdminRepository(), const AdminDashboardScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2 discount requests'));
      await tester.pumpAndSettle();
      expect(find.text('discounts page'), findsOneWidget);
    });

    testWidgets('shows an error with retry', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(FakeAdminRepository(fail: true), const AdminDashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Server unavailable'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('bookings screen', () {
    testWidgets('lists bookings with status and payment chips', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(FakeAdminRepository(), const AdminBookingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Swedish Massage'), findsOneWidget);
      expect(find.text('Rahim Uddin'), findsOneWidget);
      expect(find.text('House 12, Road 5, Dhanmondi, Dhaka'), findsOneWidget);
      expect(find.text('Awaiting verification'), findsWidgets); // payment chip (and the filter chip)
      expect(find.text('1 booking'), findsOneWidget);
    });

    testWidgets('filters by status and searches after a short pause', (tester) async {
      _tall(tester);
      final repo = FakeAdminRepository();
      await tester.pumpWidget(_app(repo, const AdminBookingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Confirmed'));
      await tester.pumpAndSettle();
      expect(repo.queries.last['status'], 'confirmed');
      expect(find.text('No bookings found'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(repo.queries.last['status'], isNull);

      await tester.enterText(find.byType(TextField), 'rahim');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(repo.queries.last['search'], 'rahim');
    });

    testWidgets('shows an error with retry', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(FakeAdminRepository(fail: true), const AdminBookingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Server unavailable'), findsOneWidget);
    });
  });

  group('booking detail actions', () {
    Future<FakeAdminRepository> open(WidgetTester tester, Map<String, dynamic> json) async {
      _tall(tester);
      final appointment = Appointment.fromJson(json);
      final repo = FakeAdminRepository(bookings: [appointment]);
      await tester.pumpWidget(_app(repo, AdminBookingDetailScreen(bookingId: appointment.id, initial: appointment)));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('a pending booking can be confirmed', (tester) async {
      final repo = await open(tester, _bookingJson());
      expect(find.text('rahim@example.com\n+880 1700 000000'), findsOneWidget);
      expect(find.text('TRX12345AB'), findsOneWidget); // transaction ID to verify

      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();
      expect(repo.statusCalls, ['b1:confirmed']);
      expect(find.text('Booking confirmed'), findsOneWidget);
    });

    testWidgets('a confirmed booking can be completed or cancelled after confirmation', (tester) async {
      final repo = await open(tester, _bookingJson(status: 'confirmed'));
      expect(find.text('Confirm booking'), findsNothing);

      await tester.tap(find.text('Mark as completed'));
      await tester.pumpAndSettle();
      expect(repo.statusCalls, ['b1:completed']);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel booking'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this booking?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel booking'));
      await tester.pumpAndSettle();
      expect(repo.statusCalls, ['b1:completed', 'b1:cancelled']);
    });

    testWidgets('a submitted payment can be verified or rejected', (tester) async {
      final repo = await open(tester, _bookingJson());
      expect(find.text('Payment: Awaiting verification'), findsOneWidget);

      await tester.tap(find.text('Verify payment (received)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Could not verify payment'));
      await tester.pumpAndSettle();
      expect(repo.paymentCalls, ['b1:paid', 'b1:failed']);
    });

    testWidgets('a paid booking offers to undo; a cancelled booking has no actions', (tester) async {
      await open(tester, _bookingJson(status: 'completed', payment: 'paid'));
      expect(find.text('Mark as unpaid'), findsOneWidget);
      expect(find.text('Confirm booking'), findsNothing);
      expect(find.text('Mark as completed'), findsNothing);
    });

    testWidgets('a cancelled booking cannot be changed', (tester) async {
      await open(tester, _bookingJson(status: 'cancelled', payment: 'unpaid'));
      expect(find.text('Confirm booking'), findsNothing);
      expect(find.textContaining('Payment:'), findsNothing);
    });
  });

  testWidgets('on phones the admin bottom bar has More, which opens the sidebar with every admin screen', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => ResponsiveShell(
          bottomItems: adminBottomNav,
          currentIndex: 0,
          menuIndex: adminMoreIndex,
          onSelect: (_) {},
          body: Builder(
            builder: (context) => Scaffold(appBar: AppBar(leading: shellMenuLeading(context)), body: const SizedBox()),
          ),
        ),
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith(_AdminAuth.new),
        unreadCountProvider.overrideWith(FixedUnread.new),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Sales reports'), findsNothing);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    for (final label in ['Sales reports', 'Payment options', 'Custom fields', 'Profile', 'Sign out']) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
