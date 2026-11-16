import 'package:flutter/material.dart';

import '../../../core/widgets/state_views.dart';

/// Placeholder until the services catalog is built in the next phase.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seba')),
      body: const EmptyView(
        icon: Icons.storefront_outlined,
        title: 'Services are coming next',
        message: 'The catalog, search and filters arrive in the next phase.',
      ),
    );
  }
}
