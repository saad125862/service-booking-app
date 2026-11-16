import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/presentation/notification_bell.dart';
import '../../shell/shell_scope.dart';
import 'chat_controller.dart';
import 'widgets/chat_bubbles.dart';

/// Starter questions in the three languages the assistant understands.
const kSuggestions = [
  ('Suggest a relaxing massage under ৳3,000', 'English'),
  ('আমার জন্য একটি ফেসিয়াল সাজেস্ট করুন', 'বাংলা'),
  ('amar jonno ekta haircut er price koto?', 'Banglish'),
  ('Can I get a discount on a massage?', 'Discount'),
];

/// Chat with the Seba assistant: ask about services in English, Bangla or Banglish.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    ref.read(chatControllerProvider.notifier).send(text);
    _input.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatControllerProvider);
    ref.listen(chatControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || prev?.sending != next.sending) _scrollToEnd();
    });
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seba Assistant'),
        leading: shellMenuLeading(context),
        actions: const [NotificationBell()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  children: [
                    for (final m in chat.messages)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChatBubble(
                          message: m,
                          onRetry: m.isError && !chat.sending ? () => ref.read(chatControllerProvider.notifier).retry() : null,
                        ),
                      ),
                    if (chat.sending) const Padding(padding: EdgeInsets.only(bottom: 12), child: TypingBubble()),
                    if (!chat.hasUserMessages) ...[
                      const SizedBox(height: 4),
                      Text('Try asking', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (text, label) in kSuggestions)
                            ActionChip(
                              avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
                              label: Text(text),
                              tooltip: label,
                              onPressed: () => _send(text),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          focusNode: _focus,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 500,
                          textInputAction: TextInputAction.send,
                          onSubmitted: _send,
                          decoration: const InputDecoration(
                            hintText: 'Ask in English, বাংলা or Banglish',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Send',
                        style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
                        onPressed: chat.sending ? null : () => _send(_input.text),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
