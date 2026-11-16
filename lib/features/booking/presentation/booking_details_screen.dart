import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/appointment.dart';
import 'booking_providers.dart';
import 'widgets/appointment_summary.dart';

/// One appointment, with a Cancel action while it is still pending.
class BookingDetailsScreen extends ConsumerStatefulWidget {
  const BookingDetailsScreen({super.key, required this.appointmentId, this.initial});

  final String appointmentId;
  final Appointment? initial;

  @override
  ConsumerState<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  bool _cancelling = false;

  Future<void> _cancel(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text('${appointment.service.name} on ${appointment.startLabel} will be cancelled and the time slot released.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep booking')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bookingRepositoryProvider).cancel(appointment.id);
      refreshBookings(ref, appointmentId: appointment.id);
      messenger.showSnackBar(const SnackBar(content: Text('Booking cancelled')));
    } on ApiException catch (e) {
      // e.g. it was confirmed in the meantime: show the reason and reload the status.
      refreshBookings(ref, appointmentId: appointment.id);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(appointmentDetailProvider(widget.appointmentId));
    final appointment = detail.value ?? widget.initial;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking details'),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/bookings')),
      ),
      body: appointment == null
          ? (detail.hasError
              ? ErrorView(
                  message: detail.error is ApiException ? (detail.error as ApiException).message : 'Please try again.',
                  onRetry: () => ref.invalidate(appointmentDetailProvider(widget.appointmentId)),
                )
              : const LoadingView())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    AppointmentSummary(appointment: appointment),
                    const SizedBox(height: 20),
                    if (appointment.isPending)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(color: Theme.of(context).colorScheme.error),
                        ),
                        onPressed: _cancelling ? null : () => _cancel(appointment),
                        icon: _cancelling
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel booking'),
                      )
                    else
                      Text(
                        switch (appointment.status) {
                          AppointmentStatus.confirmed => 'This booking is confirmed and can no longer be cancelled online.',
                          AppointmentStatus.cancelled => 'This booking was cancelled.',
                          _ => 'This booking is complete.',
                        },
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
