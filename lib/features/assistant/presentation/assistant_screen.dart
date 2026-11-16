import 'package:flutter/material.dart';

import '../../../core/widgets/state_views.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../shell/shell_scope.dart';

/// Placeholder until the AI assistant chat is built.
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seba Assistant'),
        leading: shellMenuLeading(context),
        actions: const [NotificationBell()],
      ),
      body: const EmptyView(
        icon: Icons.auto_awesome_outlined,
        title: 'Assistant coming soon',
        message: 'Ask about services in English, বাংলা or Banglish.',
      ),
    );
  }
}
