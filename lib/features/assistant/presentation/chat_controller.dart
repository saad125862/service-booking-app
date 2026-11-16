import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/assistant_repository.dart';
import '../domain/chat_message.dart';

final assistantRepositoryProvider =
    Provider<AssistantRepository>((ref) => AssistantRepository(ref.watch(apiClientProvider)));

class ChatState {
  const ChatState({required this.messages, this.sending = false, this.lastUserText});

  final List<ChatMessage> messages;
  final bool sending;

  /// The last text sent, so a failed turn can be retried.
  final String? lastUserText;

  bool get hasUserMessages => messages.any((m) => m.isUser);

  ChatState copyWith({List<ChatMessage>? messages, bool? sending, String? lastUserText}) => ChatState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        lastUserText: lastUserText ?? this.lastUserText,
      );
}

/// The conversation with the Seba assistant. Kept while the app runs (survives tab switches)
/// and reset when the user signs out.
class ChatController extends Notifier<ChatState> {
  static const maxHistory = 10;
  static const greeting =
      "Hi! I'm Seba Assistant. Ask me about our services in English, বাংলা or Banglish, "
      'and I can recommend something for you.';

  int _nextId = 1;

  @override
  ChatState build() {
    ref.watch(authProvider.select((a) => a.value?.id)); // new account => new conversation
    _nextId = 1;
    return ChatState(messages: [
      ChatMessage(id: _nextId++, role: ChatRole.assistant, text: greeting, isGreeting: true),
    ]);
  }

  List<Map<String, String>> _history() {
    final real = state.messages.where((m) => !m.isGreeting && !m.isError).toList();
    final recent = real.length > maxHistory ? real.sublist(real.length - maxHistory) : real;
    return [
      for (final m in recent)
        {'role': m.isUser ? 'user' : 'assistant', 'content': m.text.length > 1000 ? m.text.substring(0, 1000) : m.text},
    ];
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.sending) return;

    // History is what came BEFORE this message (the server adds the new one itself).
    final history = _history();
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(id: _nextId++, role: ChatRole.user, text: text)],
      sending: true,
      lastUserText: text,
    );

    try {
      final reply = await ref.read(assistantRepositoryProvider).chat(text, history);
      if (!ref.mounted) return;
      state = state.copyWith(
        sending: false,
        messages: [
          ...state.messages,
          ChatMessage(
            id: _nextId++,
            role: ChatRole.assistant,
            text: reply.reply,
            recommended: reply.recommended,
            discountRequestId: reply.discountRequestId,
          ),
        ],
      );
    } on ApiException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        sending: false,
        messages: [
          ...state.messages,
          ChatMessage(id: _nextId++, role: ChatRole.assistant, text: _friendly(e), isError: true),
        ],
      );
    }
  }

  /// Sends the last message again after a failure (the failed attempt stays out of the history).
  Future<void> retry() async {
    final text = state.lastUserText;
    if (text == null || state.sending) return;
    // Drop the error bubble and the user message that failed, then send it again.
    final messages = [...state.messages];
    if (messages.isNotEmpty && messages.last.isError) messages.removeLast();
    if (messages.isNotEmpty && messages.last.isUser) messages.removeLast();
    state = state.copyWith(messages: messages);
    await send(text);
  }

  String _friendly(ApiException e) => switch (e.code) {
        'AI_UNAVAILABLE' => 'The assistant is busy right now. Please try again in a moment.',
        'AI_NOT_CONFIGURED' => 'The assistant is not available right now.',
        'RATE_LIMITED' => 'You are sending messages too quickly. Please wait a moment.',
        _ => e.message,
      };
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);
