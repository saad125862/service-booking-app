import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';

/// Entry point for admin accounts. The dashboard, service management with the
/// dynamic form, bookings and sales reports replace this in the admin phase.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seba Admin'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: EmptyView(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Welcome, ${user?.name ?? 'admin'}',
        message: 'Signed in as an admin. Add services, bookings and sales reports are coming next.',
      ),
    );
  }
}
