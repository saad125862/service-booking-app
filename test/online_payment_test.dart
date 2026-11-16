import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seba_app/core/network/api_client.dart';
import 'package:seba_app/core/network/api_exception.dart';
import 'package:seba_app/core/providers.dart';
import 'package:seba_app/core/storage/token_storage.dart';
import 'package:seba_app/features/assistant/data/assistant_repository.dart';
import 'package:seba_app/features/assistant/domain/chat_message.dart';
import 'package:seba_app/features/assistant/presentation/assistant_screen.dart';
import 'package:seba_app/features/assistant/presentation/chat_controller.dart';
import 'package:seba_app/features/auth/domain/user.dart';
import 'package:seba_app/features/auth/presentation/auth_controller.dart';
import 'package:seba_app/features/booking/data/booking_repository.dart';
import 'package:seba_app/features/booking/domain/appointment.dart';
import 'package:seba_app/features/booking/domain/payment_link.dart';
import 'package:seba_app/features/booking/domain/payment_method.dart';
import 'package:seba_app/features/booking/presentation/booking_details_screen.dart';
import 'package:seba_app/features/booking/presentation/booking_providers.dart';
import 'package:seba_app/features/booking/presentation/widgets/pay_online_button.dart';
import 'package:seba_app/features/discounts/presentation/discount_providers.dart';
import 'package:seba_app/features/notifications/presentation/notification_providers.dart';

import 'test_helpers.dart';

Appointment _booking({PaymentStatus payment = PaymentStatus.unpaid, bool canPay = true, double price = 2000}) =>
    Appointment(
      id: 'bk-1234-abcd',
      status: AppointmentStatus.confirmed,
      startTime: DateTime.utc(2030, 1, 1, 4),
      endTime: DateTime.utc(2030, 1, 1, 5),
      startLabel: 'Tue, Jan 1, 2030, 10:00 AM',
      price: price,
      originalPrice: 2500,
      discountAmount: 500,
      paymentStatus: payment,
      canPayOnline: canPay,
      service: const AppointmentService(
        id: 's1',
        name: 'Swedish Massage',
        price: 2500,
        durationMinutes: 60,
        category: 'Wellness',
      ),
    );

class FakeRepo extends BookingRepository {
  FakeRepo({this.startError}) : super(ApiClient(tokenStorage: TokenStorage(), onUnauthorized: () {}));

  final ApiException? startError;
  Appointment current = _booking();
  int started = 0;
  int detailCalls = 0;

  @override
  Future<PaymentLink> startOnlinePayment(String id) async {
    if (startError != null) throw startError!;
    started++;
    return const PaymentLink(url: 'https://pay.example/checkout/ABC', amount: 2000, providerName: 'aamarPay');
  }

  @override
  Future<Appointment> detail(String id) async {
    detailCalls++;
    return current;
  }

  @override
  Future<List<Appointment>> list({required String scope}) async => [current];
}

class _Auth extends AuthController {
  @override
  Future<User?> build() async => const User(id: 'u1', name: 'Demo', email: 'd@e.co');
}

class FakeAssistant extends AssistantRepository {
  FakeAssistant(this.reply) : super(ApiClient(tokenStorage: TokenStorage(), onUnauthorized: () {}));
  final ChatReply reply;

  @override
  Future<ChatReply> chat(String message, List<Map<String, String>> history) async => reply;
}

Widget _app(Widget home, {required FakeRepo repo, List<Uri>? opened, bool openOk = true, FakeAssistant? assistant}) {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => home)],
  );
  return ProviderScope(
    overrides: [
      bookingRepositoryProvider.overrideWithValue(repo),
      authProvider.overrideWith(_Auth.new),
      unreadCountProvider.overrideWith(FixedUnread.new),
      myDiscountsProvider.overrideWith((ref) async => const []),
      urlOpenerProvider.overrideWithValue((url) async {
        opened?.add(url);
        return openOk;
      }),
      if (assistant != null) assistantRepositoryProvider.overrideWithValue(assistant),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

const _fast = Duration(milliseconds: 50);

void main() {
  group('PayOnlineButton', () {
    testWidgets('shows the exact amount, opens the checkout and waits', (tester) async {
      _tall(tester);
      final repo = FakeRepo();
      final opened = <Uri>[];
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: PayOnlineButton(appointmentId: 'bk-1234-abcd', amount: 2000, pollInterval: _fast),
          ),
          repo: repo,
          opened: opened,
        ),
      );

      expect(find.text('Pay ৳2,000'), findsOneWidget);
      expect(find.textContaining('exactly ৳2,000'), findsOneWidget);

      await tester.tap(find.text('Pay ৳2,000'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(repo.started, 1);
      expect(opened.single.toString(), 'https://pay.example/checkout/ABC');
      expect(find.text('Waiting for payment…'), findsOneWidget);

      // Not paid yet: keeps waiting.
      await tester.pump(_fast * 2);
      expect(find.text('Waiting for payment…'), findsOneWidget);
      expect(repo.detailCalls, greaterThan(0));

      // The server confirms the payment: the card turns into a thank-you.
      repo.current = _booking(payment: PaymentStatus.paid, canPay: false);
      await tester.pump(_fast * 2);
      await tester.pump();
      expect(find.text('Payment received. Thank you!'), findsOneWidget);
      expect(find.text('Waiting for payment…'), findsNothing);
    });

    testWidgets('"I\'ve paid" checks right away', (tester) async {
      _tall(tester);
      final repo = FakeRepo();
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: PayOnlineButton(appointmentId: 'bk-1234-abcd', amount: 2000, pollInterval: Duration(minutes: 5)),
          ),
          repo: repo,
        ),
      );
      await tester.tap(find.text('Pay ৳2,000'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(repo.detailCalls, 0);

      repo.current = _booking(payment: PaymentStatus.paid, canPay: false);
      await tester.tap(find.text("I've paid"));
      await tester.pump();
      await tester.pump();
      expect(find.text('Payment received. Thank you!'), findsOneWidget);
    });

    testWidgets('shows the server error when the link cannot be created', (tester) async {
      _tall(tester);
      final repo = FakeRepo(
        startError: const ApiException(
          message: 'Online payment is not available right now.',
          code: 'PROVIDER_UNAVAILABLE',
        ),
      );
      await tester.pumpWidget(
        _app(
          const Scaffold(body: PayOnlineButton(appointmentId: 'bk-1234-abcd', amount: 2000)),
          repo: repo,
        ),
      );
      await tester.tap(find.text('Pay ৳2,000'));
      await tester.pumpAndSettle();

      expect(find.text('Online payment is not available right now.'), findsOneWidget);
      expect(find.text('Pay ৳2,000'), findsOneWidget); // can try again
    });

    testWidgets('tells the user when the browser could not be opened', (tester) async {
      _tall(tester);
      await tester.pumpWidget(
        _app(
          const Scaffold(body: PayOnlineButton(appointmentId: 'bk-1234-abcd', amount: 2000)),
          repo: FakeRepo(),
          openOk: false,
        ),
      );
      await tester.tap(find.text('Pay ৳2,000'));
      await tester.pumpAndSettle();
      expect(find.textContaining("Couldn't open the payment page"), findsOneWidget);
    });

    testWidgets('uses the link the assistant already made for the first tap', (tester) async {
      _tall(tester);
      final repo = FakeRepo();
      final opened = <Uri>[];
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: PayOnlineButton(
              appointmentId: 'bk-1234-abcd',
              amount: 2000,
              initialUrl: 'https://pay.example/from-assistant',
              pollInterval: Duration(minutes: 5),
            ),
          ),
          repo: repo,
          opened: opened,
        ),
      );
      await tester.tap(find.text('Pay ৳2,000'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(opened.single.toString(), 'https://pay.example/from-assistant');
      expect(repo.started, 0);
    });
  });

  group('booking details', () {
    testWidgets('shows the pay button for an unpaid booking that can be paid online', (tester) async {
      _tall(tester);
      final repo = FakeRepo();
      await tester.pumpWidget(
        _app(
          BookingDetailsScreen(appointmentId: 'bk-1234-abcd', initial: repo.current),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pay securely online'), findsOneWidget);
      expect(find.text('Pay ৳2,000'), findsOneWidget);
    });

    testWidgets('hides it once the booking is paid or cannot be paid online', (tester) async {
      _tall(tester);
      final repo = FakeRepo()..current = _booking(payment: PaymentStatus.paid, canPay: false);
      await tester.pumpWidget(
        _app(
          BookingDetailsScreen(appointmentId: 'bk-1234-abcd', initial: repo.current),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pay securely online'), findsNothing);
    });
  });

  group('assistant', () {
    testWidgets('shows a pay card with the exact amount under the reply', (tester) async {
      _tall(tester);
      const link = PaymentLink(
        url: 'https://pay.example/checkout/XYZ',
        amount: 2000,
        providerName: 'aamarPay',
        appointmentId: 'bk-1234-abcd',
        serviceName: 'Swedish Massage',
      );
      final opened = <Uri>[];
      final repo = FakeRepo();
      await tester.pumpWidget(
        _app(
          const AssistantScreen(),
          repo: repo,
          opened: opened,
          assistant: FakeAssistant(
            const ChatReply(
              reply: 'Here is your secure payment link for Swedish Massage: ৳2,000.',
              language: 'en',
              paymentLink: link,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'I want to pay');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      expect(find.textContaining('secure payment link'), findsOneWidget);
      expect(find.text('Pay ৳2,000'), findsOneWidget);

      await tester.tap(find.text('Pay ৳2,000'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(opened.single.toString(), 'https://pay.example/checkout/XYZ');
    });

    test('ChatReply reads the payment link', () {
      final reply = ChatReply.fromJson({
        'reply': 'ok',
        'language': 'en',
        'paymentLink': {
          'appointmentId': 'a1',
          'serviceName': 'Facial',
          'amount': 1800,
          'provider': 'mock',
          'providerName': 'Demo checkout',
          'url': 'http://localhost:3000/pay/1',
        },
      });
      expect(reply.paymentLink!.amount, 1800);
      expect(reply.paymentLink!.appointmentId, 'a1');
      expect(ChatReply.fromJson({'reply': 'ok', 'language': 'en'}).paymentLink, isNull);
    });
  });

  test('Appointment and PaymentMethod read the online flags', () {
    final m = PaymentMethod.fromJson({
      'id': 'p',
      'code': 'aamarpay',
      'name': 'Pay online',
      'type': 'card',
      'online': true,
      'providerReady': false,
    });
    expect(m.online, isTrue);
    expect(m.providerReady, isFalse);
    expect(PaymentMethod.fromJson({'id': 'p', 'code': 'cash', 'name': 'Cash', 'type': 'cash'}).online, isFalse);
  });
}
