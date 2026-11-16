import 'package:flutter/material.dart';

import '../../../core/widgets/state_views.dart';

/// Placeholder until My Bookings is built.
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My bookings')),
      body: const EmptyView(
        icon: Icons.calendar_month_outlined,
        title: 'No bookings yet',
        message: 'Your upcoming and past appointments will show up here.',
      ),
    );
  }
}
