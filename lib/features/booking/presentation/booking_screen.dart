import 'package:flutter/material.dart';

import '../../../core/widgets/state_views.dart';
import '../../services/domain/service.dart';

/// Temporary stand-in; the date and time slot picker replaces it in the booking phase.
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key, required this.serviceId, this.service});

  final String serviceId;
  final Service? service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(service?.name ?? 'Book')),
      body: const EmptyView(
        icon: Icons.event_available_outlined,
        title: 'Booking is coming next',
        message: 'Choosing a date and time slot arrives in the next phase.',
      ),
    );
  }
}
