import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seba_app/core/network/api_client.dart';
import 'package:seba_app/core/network/api_exception.dart';
import 'package:seba_app/core/storage/token_storage.dart';
import 'package:seba_app/features/booking/data/booking_repository.dart';
import 'package:seba_app/features/booking/domain/appointment.dart';
import 'package:seba_app/features/booking/domain/availability.dart';
import 'package:seba_app/features/booking/domain/payment_method.dart';
import 'package:seba_app/features/discounts/domain/discount_request.dart';
import 'package:seba_app/features/discounts/presentation/discount_providers.dart';
import 'package:seba_app/features/booking/presentation/booking_details_screen.dart';
import 'package:seba_app/features/booking/presentation/booking_providers.dart';
import 'package:seba_app/features/booking/presentation/booking_screen.dart';
import 'package:seba_app/features/bookings/presentation/bookings_screen.dart';
import 'package:seba_app/features/services/domain/service.dart';

const _service = Service(
  id: 'svc-1',
  name: 'Swedish Massage',
  description: 'A relaxing massage.',
  price: 2500,
  durationMinutes: 60,
  category: 'Wellness',
);

Appointment _appointment({String id = 'abcdef12-0000', AppointmentStatus status = AppointmentStatus.pending}) =>
    Appointment(
      id: id,
      status: status,
      startTime: DateTime.utc(2030, 1, 1, 4),
      endTime: DateTime.utc(2030, 1, 1, 5),
      startLabel: 'Tue, Jan 1, 2030, 10:00 AM',
      notes: 'First visit',
      service: const AppointmentService(
        id: 'svc-1',
        name: 'Swedish Massage',
        price: 2500,
        durationMinutes: 60,
        category: 'Wellness',
      ),
    );

class FakeBookingRepository extends BookingRepository {
  FakeBookingRepository({
    this.upcoming = const [],
    this.past = const [],
    this.createError,
    this.listError,
  }) : super(ApiClient(tokenStorage: TokenStorage(), onUnauthorized: () {}));

  final List<Appointment> upcoming;
  final List<Appointment> past;
  final ApiException? createError;
  final ApiException? listError;
  final List<DateTime> created = [];
  final List<String> addresses = [];
  final List<String> paymentMethodIds = [];
  final List<String?> references = [];
  final List<String> cancelled = [];
  var availabilityCalls = 0;

  static final slots = [
    TimeSlot(start: DateTime.utc(2030, 1, 1, 3), end: DateTime.utc(2030, 1, 1, 4), label: '9:00 AM', available: true),
    TimeSlot(start: DateTime.utc(2030, 1, 1, 4), end: DateTime.utc(2030, 1, 1, 5), label: '10:00 AM', available: false),
    TimeSlot(start: DateTime.utc(2030, 1, 1, 5), end: DateTime.utc(2030, 1, 1, 6), label: '11:00 AM', available: true),
  ];

  static const cash = PaymentMethod(id: 'pm-cash', code: 'cash', name: 'Cash on service', type: PaymentType.cash);
  static const bkash = PaymentMethod(
    id: 'pm-bkash',
    code: 'bkash',
    name: 'bKash',
    type: PaymentType.mobileWallet,
    instructions: 'Send the amount to 01700-000000 (Personal), then enter the transaction ID.',
    requiresReference: true,
  );

  @override
  Future<List<PaymentMethod>> paymentMethods() async => const [cash, bkash];

  @override
  Future<Availability> availability(String serviceId, String date) async {
    availabilityCalls++;
    return Availability(date: date, timeZone: 'Asia/Dhaka', slots: slots);
  }

  @override
  Future<Appointment> create({
    required String serviceId,
    required DateTime startTime,
    required String address,
    required String paymentMethodId,
    String? paymentReference,
    String? notes,
  }) async {
    if (createError != null) throw createError!;
    created.add(startTime);
    addresses.add(address);
    paymentMethodIds.add(paymentMethodId);
    references.add(paymentReference);
    return _appointment();
  }

  @override
  Future<List<Appointment>> list({required String scope}) async {
    if (listError != null) throw listError!;
    return scope == 'upcoming' ? upcoming : past;
  }

  @override
  Future<Appointment> detail(String id) async => [...upcoming, ...past].firstWhere((a) => a.id == id);

  @override
  Future<Appointment> cancel(String id) async {
    cancelled.add(id);
    return _appointment(id: id, status: AppointmentStatus.cancelled);
  }
}

Future<void> _tallView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _routerApp(FakeBookingRepository repo, Widget home, {List<DiscountRequest> discounts = const []}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => home),
    GoRoute(path: '/bookings', builder: (_, _) => const Text('bookings tab')),
    GoRoute(path: '/booking/:id/confirmed', builder: (_, s) => Text('confirmed ${s.pathParameters['id']}')),
    GoRoute(path: '/booking/:id', builder: (_, s) => Text('details ${s.pathParameters['id']}')),
  ]);
  return ProviderScope(
    overrides: [
      bookingRepositoryProvider.overrideWithValue(repo),
      myDiscountsProvider.overrideWith((ref) async => discounts),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('models', () {
    test('Appointment.fromJson parses the API payload', () {
      final a = Appointment.fromJson({
        'id': '5d85757b-32b8-4270-8c16-4221f140fa06',
        'status': 'confirmed',
        'startTime': '2030-01-01T04:00:00.000Z',
        'endTime': '2030-01-01T05:00:00.000Z',
        'startLabel': 'Tue, Jan 1, 2030, 10:00 AM',
        'timeZone': 'Asia/Dhaka',
        'address': 'House 12, Dhanmondi',
        'notes': null,
        'createdAt': '2026-11-16T10:00:00.000Z',
        'service': {
          'id': 's',
          'name': 'Yoga',
          'price': 1200,
          'durationMinutes': 60,
          'imageUrl': null,
          'category': 'Fitness',
        },
      });
      expect(a.status, AppointmentStatus.confirmed);
      expect(a.isPending, isFalse);
      expect(a.reference, '5D85757B');
      expect(a.service.price, 1200.0);
      expect(a.address, 'House 12, Dhanmondi');
    });

    test('unknown statuses fall back to pending', () {
      expect(AppointmentStatus.parse('weird'), AppointmentStatus.pending);
    });

    test('Availability reports whether any slot is free', () {
      final a = Availability.fromJson({
        'date': '2030-01-01',
        'timeZone': 'UTC',
        'slots': [
          {'start': '2030-01-01T03:00:00.000Z', 'end': '2030-01-01T04:00:00.000Z', 'label': '9:00 AM', 'available': false},
        ],
      });
      expect(a.hasAvailableSlot, isFalse);
    });
  });

  group('booking screen', () {
    testWidgets('shows slots, disables taken ones and only enables confirm after choosing a time', (tester) async {
      await _tallView(tester);
      final repo = FakeBookingRepository();
      await tester.pumpWidget(_routerApp(repo, const BookingScreen(serviceId: 'svc-1', service: _service)));
      await tester.pumpAndSettle();

      expect(find.text('Select a date'), findsOneWidget);
      expect(find.text('9:00 AM'), findsOneWidget);
      expect(find.text('11:00 AM'), findsOneWidget);

      final taken = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '10:00 AM'));
      expect(taken.onSelected, isNull);

      expect(find.text('Select a time'), findsWidgets); // section title + disabled button label
      final disabled = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(disabled.onPressed, isNull);

      await tester.tap(find.text('9:00 AM'));
      await tester.pump();
      expect(find.text('Confirm booking'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
    });

    testWidgets('confirming books the chosen slot and opens the confirmation screen', (tester) async {
      await _tallView(tester);
      final repo = FakeBookingRepository();
      await tester.pumpWidget(_routerApp(repo, const BookingScreen(serviceId: 'svc-1', service: _service)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('11:00 AM'));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextFormField, 'Where should we come?'), 'House 12, Road 5, Dhanmondi');
      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();

      expect(repo.created, [DateTime.utc(2030, 1, 1, 5)]);
      expect(repo.addresses, ['House 12, Road 5, Dhanmondi']);
      expect(find.text('confirmed abcdef12-0000'), findsOneWidget);
    });

    testWidgets('an address is required before booking', (tester) async {
      await _tallView(tester);
      final repo = FakeBookingRepository();
      await tester.pumpWidget(_routerApp(repo, const BookingScreen(serviceId: 'svc-1', service: _service)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('9:00 AM'));
      await tester.pump();
      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the address where we should come'), findsOneWidget);
      expect(repo.created, isEmpty);
    });

    testWidgets('a slot that was just taken shows the reason, clears the choice and reloads slots', (tester) async {
      await _tallView(tester);
      final repo = FakeBookingRepository(
        createError: const ApiException(
          message: 'That time slot was just taken, please pick another',
          code: 'SLOT_UNAVAILABLE',
          statusCode: 409,
        ),
      );
      await tester.pumpWidget(_routerApp(repo, const BookingScreen(serviceId: 'svc-1', service: _service)));
      await tester.pumpAndSettle();
      final callsBefore = repo.availabilityCalls;

      await tester.tap(find.text('9:00 AM'));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextFormField, 'Where should we come?'), 'House 12, Road 5, Dhanmondi');
      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();

      expect(find.text('That time slot was just taken, please pick another'), findsOneWidget);
      expect(find.text('Select a time'), findsWidgets);
      expect(repo.availabilityCalls, greaterThan(callsBefore));
      expect(repo.created, isEmpty);
    });
  });

  group('payment and discount', () {
    testWidgets('a cash booking sends the payment method and needs no transaction ID', (tester) async {
      await _tallView(tester);
      final repo = FakeBookingRepository();
      await tester.pumpWidget(_routerApp(repo, const BookingScreen(serviceId: 'svc-1', service: _service)));
      await tester.pumpAndSettle();

      expect(find.text('Cash on service'), findsOneWidget);
      expect(find.text('bKash'), findsOneWidget);
      await tester.tap(find.text('11:00 AM'));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextFormField, 'Where should we come?'), 'House 12, Road 5, Dhanmondi');
      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();

      expect(repo.paymentMethodIds, ['pm-cash']);
      expect(repo.references, [null]);
    });

    testWidgets('bKash shows its instructions and requires the transaction ID', (tester) async {
      await _tallView(tester);
      final repo = FakeBookingRepository();
      await tester.pumpWidget(_routerApp(repo, const BookingScreen(serviceId: 'svc-1', service: _service)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('bKash'));
      await tester.pump();
      expect(find.textContaining('01700-000000'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'bKash transaction ID'), findsOneWidget);

      await tester.tap(find.text('9:00 AM'));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextFormField, 'Where should we come?'), 'House 12, Road 5, Dhanmondi');
      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();
      expect(find.text('Enter the transaction ID after sending the money'), findsOneWidget);
      expect(repo.created, isEmpty);

      await tester.enterText(find.widgetWithText(TextFormField, 'bKash transaction ID'), 'TRX12345AB');
      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();
      expect(repo.paymentMethodIds, ['pm-bkash']);
      expect(repo.references, ['TRX12345AB']);
    });

    testWidgets('an approved discount for this service is shown and the discounted price is previewed', (tester) async {
      await _tallView(tester);
      final discount = DiscountRequest(
        id: 'd1',
        status: 'approved',
        message: 'discount?',
        language: 'en',
        createdAt: DateTime(2026, 11, 16),
        serviceId: 'svc-1',
        serviceName: 'Swedish Massage',
        discountType: 'percent',
        discountValue: 20,
      );
      await tester.pumpWidget(_routerApp(
        FakeBookingRepository(),
        const BookingScreen(serviceId: 'svc-1', service: _service),
        discounts: [discount],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('20% off'), findsOneWidget);
      expect(find.textContaining('this one order only'), findsOneWidget);
      await tester.tap(find.text('9:00 AM'));
      await tester.pump();
      expect(find.text('৳2,500'), findsWidgets); // struck-through list price
      expect(find.text('৳2,000'), findsOneWidget); // price after the discount
    });

    testWidgets('a discount for another service is not shown', (tester) async {
      await _tallView(tester);
      final other = DiscountRequest(
        id: 'd2',
        status: 'approved',
        message: 'discount?',
        language: 'en',
        createdAt: DateTime(2026, 11, 16),
        serviceId: 'someone-else',
        discountType: 'percent',
        discountValue: 20,
      );
      await tester.pumpWidget(_routerApp(
        FakeBookingRepository(),
        const BookingScreen(serviceId: 'svc-1', service: _service),
        discounts: [other],
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('approved discount'), findsNothing);
    });
  });

  group('my bookings', () {
    testWidgets('lists upcoming and past bookings with their status', (tester) async {
      await _tallView(tester);
      final repo = FakeBookingRepository(
        upcoming: [_appointment()],
        past: [_appointment(id: 'ffffffff-0000', status: AppointmentStatus.completed)],
      );
      await tester.pumpWidget(_routerApp(repo, const BookingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Swedish Massage'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('shows friendly empty states', (tester) async {
      await _tallView(tester);
      await tester.pumpWidget(_routerApp(FakeBookingRepository(), const BookingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No upcoming bookings'), findsOneWidget);
      expect(find.text('Browse services'), findsOneWidget);

      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('No past bookings'), findsOneWidget);
    });

    testWidgets('shows an error with retry when bookings cannot load', (tester) async {
      await _tallView(tester);
      final repo = FakeBookingRepository(listError: const ApiException(message: 'Server unavailable', code: 'NETWORK'));
      await tester.pumpWidget(_routerApp(repo, const BookingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Server unavailable'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('booking details', () {
    testWidgets('a pending booking can be cancelled after confirming the dialog', (tester) async {
      await _tallView(tester);
      final repo = FakeBookingRepository(upcoming: [_appointment()]);
      await tester.pumpWidget(_routerApp(
        repo,
        BookingDetailsScreen(appointmentId: 'abcdef12-0000', initial: _appointment()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('First visit'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel booking'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this booking?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Cancel booking'));
      await tester.pumpAndSettle();

      expect(repo.cancelled, ['abcdef12-0000']);
      expect(find.text('Booking cancelled'), findsOneWidget);
    });

    testWidgets('a confirmed booking has no cancel button', (tester) async {
      await _tallView(tester);
      final confirmed = _appointment(status: AppointmentStatus.confirmed);
      final repo = FakeBookingRepository(upcoming: [confirmed]);
      await tester.pumpWidget(_routerApp(
        repo,
        BookingDetailsScreen(appointmentId: confirmed.id, initial: confirmed),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cancel booking'), findsNothing);
      expect(find.textContaining('can no longer be cancelled'), findsOneWidget);
    });
  });
}
