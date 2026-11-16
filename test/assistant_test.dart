import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seba_app/core/network/api_client.dart';
import 'package:seba_app/core/network/api_exception.dart';
import 'package:seba_app/core/storage/token_storage.dart';
import 'package:seba_app/features/assistant/data/assistant_repository.dart';
import 'package:seba_app/features/assistant/domain/chat_message.dart';
import 'package:seba_app/features/assistant/presentation/assistant_screen.dart';
import 'package:seba_app/features/assistant/presentation/chat_controller.dart';
import 'package:seba_app/features/auth/domain/user.dart';
import 'package:seba_app/features/auth/presentation/auth_controller.dart';
import 'package:seba_app/features/discounts/domain/discount_request.dart';
import 'package:seba_app/features/discounts/presentation/discount_providers.dart';
import 'package:seba_app/features/notifications/presentation/notification_providers.dart';

import 'test_helpers.dart';

class FakeAssistantRepository extends AssistantRepository {
  FakeAssistantRepository(this.replies) : super(ApiClient(tokenStorage: TokenStorage(), onUnauthorized: () {}));

  /// Scripted outcomes, one per call: a [ChatReply] or an [ApiException] to throw.
  final List<Object> replies;
  final List<String> messages = [];
  final List<List<Map<String, String>>> histories = [];

  @override
  Future<ChatReply> chat(String message, List<Map<String, String>> history) async {
    messages.add(message);
    histories.add(history);
    final next = replies.removeAt(0);
    if (next is ApiException) throw next;
    return next as ChatReply;
  }
}

class _Auth extends AuthController {
  @override
  Future<User?> build() async => const User(id: 'u1', name: 'Demo', email: 'd@e.co');
}

const _massage = RecommendedService(
  id: 'svc-1',
  name: 'Swedish Massage',
  category: 'Wellness',
  price: 2500,
  durationMinutes: 60,
);

DiscountRequest _request(String status, {String? reply}) => DiscountRequest(
      id: 'dr-1',
      status: status,
      message: 'discount?',
      language: 'en',
      createdAt: DateTime(2026, 11, 16),
      serviceId: 'svc-1',
      serviceName: 'Swedish Massage',
      discountType: status == 'pending' ? null : 'percent',
      discountValue: status == 'pending' ? null : 15,
      reply: reply,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

Widget _app(FakeAssistantRepository repo, {List<DiscountRequest> Function()? discounts}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => const AssistantScreen()),
    GoRoute(path: '/service/:id', builder: (_, s) => Text('service ${s.pathParameters['id']}')),
  ]);
  return ProviderScope(
    overrides: [
      assistantRepositoryProvider.overrideWithValue(repo),
      authProvider.overrideWith(_Auth.new),
      unreadCountProvider.overrideWith(FixedUnread.new),
      myDiscountsProvider.overrideWith((ref) async => discounts?.call() ?? const []),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Types a message and sends it. [settle] false is for screens showing a spinner (never "settles").
Future<void> _type(WidgetTester tester, String text, {bool settle = true}) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byTooltip('Send'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('greets the user and suggests questions in English, Bangla and Banglish', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(FakeAssistantRepository([])));
    await tester.pumpAndSettle();

    expect(find.textContaining("I'm Seba Assistant"), findsOneWidget);
    expect(find.text('Suggest a relaxing massage under ৳3,000'), findsOneWidget);
    expect(find.text('আমার জন্য একটি ফেসিয়াল সাজেস্ট করুন'), findsOneWidget);
    expect(find.text('amar jonno ekta haircut er price koto?'), findsOneWidget);
    expect(find.text('Can I get a discount on a massage?'), findsOneWidget);
  });

  testWidgets('tapping a suggestion sends it; the reply shows recommended services and the chips disappear', (tester) async {
    _tall(tester);
    final repo = FakeAssistantRepository([
      const ChatReply(reply: 'Try the Swedish Massage, it fits your budget.', language: 'en', recommended: [_massage]),
    ]);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Suggest a relaxing massage under ৳3,000'));
    await tester.pumpAndSettle();

    expect(repo.messages, ['Suggest a relaxing massage under ৳3,000']);
    expect(find.text('Try the Swedish Massage, it fits your budget.'), findsOneWidget);
    expect(find.text('Swedish Massage'), findsOneWidget); // recommendation card
    expect(find.text('৳2,500 · 1 h'), findsOneWidget);
    expect(find.text('Try asking'), findsNothing);

    await tester.tap(find.text('Swedish Massage'));
    await tester.pumpAndSettle();
    expect(find.text('service svc-1'), findsOneWidget); // the card opens the service
  });

  testWidgets('keeps the conversation as history for the next message', (tester) async {
    _tall(tester);
    final repo = FakeAssistantRepository([
      const ChatReply(reply: 'The facial takes 45 minutes.', language: 'en'),
      const ChatReply(reply: 'It costs ৳1,800.', language: 'en'),
    ]);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await _type(tester, 'How long is the facial?');
    await _type(tester, 'And the price?');

    expect(repo.histories[0], isEmpty); // the greeting is not sent
    expect(repo.histories[1], [
      {'role': 'user', 'content': 'How long is the facial?'},
      {'role': 'assistant', 'content': 'The facial takes 45 minutes.'},
    ]);
  });

  testWidgets('Bangla and Banglish messages are sent and shown as written', (tester) async {
    _tall(tester);
    final repo = FakeAssistantRepository([
      const ChatReply(reply: 'আপনার জন্য Swedish Massage ভালো হবে।', language: 'bn'),
      const ChatReply(reply: 'Apnar jonno Classic Facial valo hobe.', language: 'banglish'),
    ]);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await _type(tester, 'আমার একটা ম্যাসাজ দরকার');
    await _type(tester, 'amar jonno ekta facial lagbe');

    expect(repo.messages, ['আমার একটা ম্যাসাজ দরকার', 'amar jonno ekta facial lagbe']);
    expect(find.text('আপনার জন্য Swedish Massage ভালো হবে।'), findsOneWidget);
    expect(find.text('Apnar jonno Classic Facial valo hobe.'), findsOneWidget);
  });

  testWidgets('a failed reply shows a friendly error and Try again resends the message', (tester) async {
    _tall(tester);
    final repo = FakeAssistantRepository([
      const ApiException(message: 'raw', code: 'AI_UNAVAILABLE', statusCode: 503),
      const ChatReply(reply: 'Here you go!', language: 'en'),
    ]);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await _type(tester, 'Hello');
    expect(find.text('The assistant is busy right now. Please try again in a moment.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repo.messages, ['Hello', 'Hello']);
    expect(find.text('Here you go!'), findsOneWidget);
    expect(find.textContaining('busy right now'), findsNothing);
    expect(find.text('Hello'), findsOneWidget); // the failed attempt was replaced, not duplicated
  });

  group('discount requests wait for an admin', () {
    testWidgets('shows a waiting card, then the assistant answers when the admin approves', (tester) async {
      _tall(tester);
      var requests = [_request('pending')];
      final repo = FakeAssistantRepository([
        const ChatReply(
          reply: 'I have passed your request to an admin who is reviewing it.',
          language: 'en',
          discountRequestId: 'dr-1',
        ),
      ]);
      await tester.pumpWidget(_app(repo, discounts: () => requests));
      await tester.pumpAndSettle();

      await _type(tester, 'Can I get a discount on the massage?', settle: false);
      expect(find.text('I have passed your request to an admin who is reviewing it.'), findsOneWidget);
      expect(find.text('Waiting for an admin'), findsOneWidget);
      expect(find.textContaining('An admin is processing your discount request'), findsOneWidget);

      // The admin approves: the card now shows the assistant's answer.
      requests = [_request('approved', reply: 'Good news! An admin approved 15% off Swedish Massage.')];
      ProviderScope.containerOf(tester.element(find.byType(AssistantScreen))).invalidate(myDiscountsProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Waiting for an admin'), findsNothing);
      expect(find.text('Discount approved'), findsOneWidget);
      expect(find.text('Good news! An admin approved 15% off Swedish Massage.'), findsOneWidget);
      expect(find.textContaining('15% off'), findsWidgets);
      expect(find.textContaining('one order only'), findsOneWidget);
    });

    testWidgets('a declined request shows the assistant\'s polite answer', (tester) async {
      _tall(tester);
      var requests = [_request('pending')];
      final repo = FakeAssistantRepository([
        const ChatReply(reply: 'An admin is reviewing it.', language: 'en', discountRequestId: 'dr-1'),
      ]);
      await tester.pumpWidget(_app(repo, discounts: () => requests));
      await tester.pumpAndSettle();
      await _type(tester, 'discount please', settle: false);

      requests = [_request('declined', reply: 'Sorry, we cannot offer a discount this time.')];
      ProviderScope.containerOf(tester.element(find.byType(AssistantScreen))).invalidate(myDiscountsProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Discount not approved'), findsOneWidget);
      expect(find.text('Sorry, we cannot offer a discount this time.'), findsOneWidget);
    });
  });

  group('DiscountRequest', () {
    test('computes the amount for percent and fixed discounts, never above the price', () {
      final percent = _request('approved');
      expect(percent.amountFor(2500), 375.0);
      expect(percent.discountLabel, '15% off');

      final fixed = DiscountRequest(
        id: 'x',
        status: 'approved',
        message: '',
        language: 'en',
        createdAt: null_,
        discountType: 'fixed',
        discountValue: 3000,
      );
      expect(fixed.amountFor(1800), 1800); // capped at the price
      expect(fixed.discountLabel, '৳3,000 off');
    });

    test('an approved discount applies to its service or to any service', () {
      expect(_request('approved').appliesTo('svc-1'), isTrue);
      expect(_request('approved').appliesTo('svc-2'), isFalse);
      expect(_request('pending').appliesTo('svc-1'), isFalse);
      expect(_request('used').appliesTo('svc-1'), isFalse);
    });
  });
}

final null_ = DateTime(2026, 11, 16);
