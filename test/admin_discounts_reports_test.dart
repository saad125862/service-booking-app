import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seba_app/core/network/api_client.dart';
import 'package:seba_app/core/network/api_exception.dart';
import 'package:seba_app/core/storage/token_storage.dart';
import 'package:seba_app/features/admin/data/admin_repository.dart';
import 'package:seba_app/features/admin/domain/sales_report.dart';
import 'package:seba_app/features/admin/presentation/admin_discounts_screen.dart';
import 'package:seba_app/features/admin/presentation/admin_providers.dart';
import 'package:seba_app/features/admin/presentation/admin_reports_screen.dart';
import 'package:seba_app/features/discounts/domain/discount_request.dart';
import 'package:seba_app/features/notifications/presentation/notification_providers.dart';

import 'test_helpers.dart';

DiscountRequest _request({
  String id = 'd1',
  String status = 'pending',
  String customer = 'Rahim Uddin',
  String service = 'Deep Tissue Massage',
  num price = 3000,
  String message = 'Can I get a discount please?',
  String language = 'en',
  String? type,
  num? value,
  String? reply,
}) => DiscountRequest.fromJson({
  'id': id,
  'status': status,
  'message': message,
  'language': language,
  'service': {'id': 's1', 'name': service, 'price': price},
  'discountType': type,
  'discountValue': value,
  'reply': reply,
  'createdAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
  'expiresAt': status == 'approved' ? '2030-01-01T00:00:00.000Z' : null,
  'customer': {'id': 'c1', 'name': customer, 'email': 'rahim@example.com'},
});

SalesReport _report({String groupBy = 'day', bool empty = false}) => SalesReport.fromJson({
  'from': '2026-11-01',
  'to': '2026-11-03',
  'groupBy': groupBy,
  'groupLabel': {'day': 'Date', 'service': 'Service', 'category': 'Category', 'payment': 'Payment method'}[groupBy],
  'timeZone': 'Asia/Dhaka',
  'summary': {
    'revenue': empty ? 0 : 7500,
    'bookings': empty ? 0 : 3,
    'averageOrderValue': empty ? 0 : 2500,
    'discountsGiven': empty ? 0 : 500,
    'paidAmount': empty ? 0 : 5000,
    'unpaidAmount': empty ? 0 : 2500,
    'cancelledBookings': 1,
    'pendingBookings': 2,
  },
  'rows': empty
      ? []
      : groupBy == 'day'
      ? [
          {'key': '2026-11-01', 'bookings': 1, 'revenue': 2500, 'discounts': 0},
          {'key': '2026-11-02', 'bookings': 0, 'revenue': 0, 'discounts': 0},
          {'key': '2026-11-03', 'bookings': 2, 'revenue': 5000, 'discounts': 500},
        ]
      : [
          {'key': 'Swedish Massage', 'bookings': 2, 'revenue': 5000, 'discounts': 500},
          {'key': 'Classic Facial', 'bookings': 1, 'revenue': 2500, 'discounts': 0},
        ],
});

class FakeRepo extends AdminRepository {
  FakeRepo({List<DiscountRequest>? requests, this.emptyReport = false, this.failReport = false})
    : requests_ =
          requests ??
          [
            _request(),
            _request(
              id: 'd2',
              status: 'approved',
              customer: 'Karim',
              type: 'percent',
              value: 10,
              reply: 'Good news, Karim!',
            ),
          ],
      super(ApiClient(tokenStorage: TokenStorage(), onUnauthorized: () {}));

  final List<DiscountRequest> requests_;
  final bool emptyReport;
  final bool failReport;
  final List<String?> statusQueries = [];
  final List<Map<String, Object?>> approvals = [];
  final List<Map<String, Object?>> declines = [];
  final List<ReportQuery> reportQueries = [];

  @override
  Future<List<DiscountRequest>> discountRequests({String? status}) async {
    statusQueries.add(status);
    return requests_.where((r) => status == null || r.status == status).toList();
  }

  @override
  Future<DiscountRequest> approveDiscount(
    String id, {
    required String type,
    required num value,
    int expiresInDays = 14,
    String? note,
  }) async {
    approvals.add({'id': id, 'type': type, 'value': value, 'days': expiresInDays, 'note': note});
    requests_.removeWhere((r) => r.id == id);
    return _request(id: id, status: 'approved');
  }

  @override
  Future<DiscountRequest> declineDiscount(String id, {String? note}) async {
    declines.add({'id': id, 'note': note});
    requests_.removeWhere((r) => r.id == id);
    return _request(id: id, status: 'declined');
  }

  @override
  Future<SalesReport> salesReport({required String from, required String to, required String groupBy}) async {
    reportQueries.add((from: from, to: to, groupBy: groupBy));
    if (failReport) throw const ApiException(message: 'Server unavailable', code: 'NETWORK');
    return _report(groupBy: groupBy, empty: emptyReport);
  }
}

Widget _app(FakeRepo repo, Widget home) => ProviderScope(
  overrides: [adminRepositoryProvider.overrideWithValue(repo), unreadCountProvider.overrideWith(FixedUnread.new)],
  child: MaterialApp(home: home),
);

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Discount requests', () {
    testWidgets('shows pending requests first with the customer, service and message', (tester) async {
      _tall(tester);
      final repo = FakeRepo();
      await tester.pumpWidget(_app(repo, const AdminDiscountsScreen()));
      await tester.pumpAndSettle();

      expect(repo.statusQueries, ['pending']);
      expect(find.text('Rahim Uddin'), findsOneWidget);
      expect(find.textContaining('Deep Tissue Massage'), findsOneWidget);
      expect(find.textContaining('Can I get a discount please?'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('approving with a percent sends the amount and shows the customer price', (tester) async {
      _tall(tester);
      final repo = FakeRepo();
      await tester.pumpWidget(_app(repo, const AdminDiscountsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();
      expect(find.text('Approve discount'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Percent off'), '20');
      await tester.pump();
      expect(find.textContaining('customer pays ৳2,400'), findsOneWidget);

      await tester.tap(
        find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Approve')),
      );
      await tester.pumpAndSettle();

      expect(repo.approvals.single, {'id': 'd1', 'type': 'percent', 'value': 20.0, 'days': 14, 'note': ''});
      expect(find.textContaining('Approved. The assistant'), findsOneWidget);
      expect(find.text('Rahim Uddin'), findsNothing); // gone from the pending list
    });

    testWidgets('a fixed amount can be chosen and a percent above 90 is refused', (tester) async {
      _tall(tester);
      final repo = FakeRepo();
      await tester.pumpWidget(_app(repo, const AdminDiscountsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Percent off'), '95');
      await tester.tap(
        find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Approve')),
      );
      await tester.pumpAndSettle();
      expect(find.text('At most 90%'), findsOneWidget);
      expect(repo.approvals, isEmpty);

      await tester.tap(find.text('Amount ৳'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Taka off'), '300');
      await tester.tap(
        find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Approve')),
      );
      await tester.pumpAndSettle();
      expect(repo.approvals.single['type'], 'fixed');
      expect(repo.approvals.single['value'], 300.0);
    });

    testWidgets('declining sends the reason', (tester) async {
      _tall(tester);
      final repo = FakeRepo();
      await tester.pumpWidget(_app(repo, const AdminDiscountsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Decline'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Already our lowest price');
      await tester.tap(
        find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Decline')),
      );
      await tester.pumpAndSettle();

      expect(repo.declines.single, {'id': 'd1', 'note': 'Already our lowest price'});
      expect(find.textContaining('Declined. The assistant'), findsOneWidget);
    });

    testWidgets('the Approved tab shows the discount and what the assistant told the customer', (tester) async {
      _tall(tester);
      final repo = FakeRepo();
      await tester.pumpWidget(_app(repo, const AdminDiscountsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Approved'));
      await tester.pumpAndSettle();

      expect(find.text('Karim'), findsOneWidget);
      expect(find.textContaining('10% off'), findsOneWidget);
      expect(find.text('Good news, Karim!'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
    });

    testWidgets('empty pending list explains what will show up', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(FakeRepo(requests: []), const AdminDiscountsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Nothing waiting'), findsOneWidget);
    });
  });

  group('Sales reports', () {
    final today = DateTime(2026, 11, 16);

    test('businessToday is Dhaka time (UTC+6)', () {
      expect(businessToday(DateTime.utc(2026, 11, 16, 20, 0)), DateTime(2026, 11, 17));
      expect(businessToday(DateTime.utc(2026, 11, 16, 3, 0)), DateTime(2026, 11, 16));
    });

    test('toCsv matches the API export and quotes commas', () {
      final csv = SalesReport.fromJson({
        'from': '2026-11-01',
        'to': '2026-11-03',
        'groupBy': 'service',
        'groupLabel': 'Service',
        'summary': {
          'revenue': 5000,
          'bookings': 2,
          'averageOrderValue': 2500,
          'discountsGiven': 0,
          'paidAmount': 0,
          'unpaidAmount': 5000,
          'cancelledBookings': 0,
          'pendingBookings': 0,
        },
        'rows': [
          {'key': 'Hair, Cut', 'bookings': 2, 'revenue': 5000, 'discounts': 0},
        ],
      }).toCsv();
      expect(csv, 'Service,Bookings,Revenue (BDT),Discounts (BDT)\n"Hair, Cut",2,5000.0,0.0\nTotal,2,5000.0,0.0');
    });

    testWidgets('loads the last 30 days by day and shows the summary and table', (tester) async {
      _tall(tester);
      final repo = FakeRepo();
      await tester.pumpWidget(_app(repo, AdminReportsScreen(today: today)));
      await tester.pumpAndSettle();

      expect(repo.reportQueries.first, (from: '2026-10-18', to: '2026-11-16', groupBy: 'day'));
      expect(find.text('৳7,500'), findsWidgets);
      expect(find.text('3 bookings'), findsOneWidget);
      expect(find.text('Revenue per day'), findsOneWidget);
      expect(find.text('Sun, 1 Nov'), findsOneWidget);
    });

    testWidgets('presets and grouping reload the report', (tester) async {
      _tall(tester);
      final repo = FakeRepo();
      await tester.pumpWidget(_app(repo, AdminReportsScreen(today: today)));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Last 7 days'));
      await tester.pumpAndSettle();
      expect(repo.reportQueries.last, (from: '2026-11-10', to: '2026-11-16', groupBy: 'day'));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Last month'));
      await tester.pumpAndSettle();
      expect(repo.reportQueries.last, (from: '2026-10-01', to: '2026-10-31', groupBy: 'day'));

      await tester.tap(find.widgetWithText(FilterChip, 'By service'));
      await tester.pumpAndSettle();
      expect(repo.reportQueries.last.groupBy, 'service');
      expect(find.text('Swedish Massage'), findsWidgets);
      expect(find.text('Revenue by service'), findsOneWidget);
    });

    testWidgets('Copy CSV puts the report on the clipboard', (tester) async {
      _tall(tester);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(_app(FakeRepo(), AdminReportsScreen(today: today)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Copy CSV'));
      await tester.tap(find.text('Copy CSV'));
      await tester.pumpAndSettle();

      expect(copied, startsWith('Date,Bookings,Revenue (BDT),Discounts (BDT)'));
      expect(find.textContaining('CSV copied'), findsOneWidget);
    });

    testWidgets('an empty period says so', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(FakeRepo(emptyReport: true), AdminReportsScreen(today: today)));
      await tester.pumpAndSettle();
      expect(find.text('No sales in this period'), findsOneWidget);
    });

    testWidgets('shows an error with retry', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(FakeRepo(failReport: true), AdminReportsScreen(today: today)));
      await tester.pumpAndSettle();
      expect(find.text('Server unavailable'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
