import 'package:flutter/material.dart';

import '../../../core/widgets/state_views.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../shell/shell_scope.dart';

/// Stand-in for admin sections that are built in the next phases.
class AdminPlaceholderScreen extends StatelessWidget {
  const AdminPlaceholderScreen({super.key, required this.title, required this.icon, required this.message});

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), leading: shellMenuLeading(context), actions: const [NotificationBell()]),
      body: EmptyView(icon: icon, title: title, message: message),
    );
  }
}
