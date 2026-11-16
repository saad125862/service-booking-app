import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/state_views.dart';
import '../../booking/domain/appointment.dart';
import '../../booking/domain/payment_method.dart';
import '../../booking/presentation/widgets/appointment_summary.dart';
import 'admin_providers.dart';

/// One booking for admins: customer details, status actions and payment verification.
class AdminBookingDetailScreen extends ConsumerStatefulWidget {
  const AdminBookingDetailScreen({super.key, required this.bookingId, this.initial});

  final String bookingId;
  final Appointment? initial;

  @override
  ConsumerState<AdminBookingDetailScreen> createState() => _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends ConsumerState<AdminBookingDetailScreen> {
  bool _busy = false;

  Future<void> _run(Future<Appointment> Function() action, String success) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      refreshAdminData(ref, bookingId: widget.bookingId);
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } on ApiException catch (e) {
      refreshAdminData(ref, bookingId: widget.bookingId);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(Appointment a, String status, String success, {bool confirm = false}) async {
    if (confirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel this booking?'),
          content: Text('${a.service.name} for ${a.customer?.name ?? 'the customer'} on ${a.startLabel} will be cancelled and the customer will be notified.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel booking'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await _run(() => ref.read(adminRepositoryProvider).setStatus(a.id, status), success);
  }

  Future<void> _setPayment(Appointment a, String status, String success) =>
      _run(() => ref.read(adminRepositoryProvider).setPayment(a.id, status), success);

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(adminBookingProvider(widget.bookingId));
    final appointment = detail.value ?? widget.initial;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking'),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/admin/bookings')),
      ),
      body: appointment == null
          ? (detail.hasError
              ? ErrorView(
                  message: detail.error is ApiException ? (detail.error as ApiException).message : 'Please try again.',
                  onRetry: () => ref.invalidate(adminBookingProvider(widget.bookingId)),
                )
              : const LoadingView())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    if (appointment.customer != null)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            child: Icon(Icons.person_outline, color: scheme.onPrimaryContainer),
                          ),
                          title: Text(appointment.customer!.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text([appointment.customer!.email, ?appointment.customer!.phone].join('\n')),
                          isThreeLine: appointment.customer!.phone != null,
                        ),
                      ),
                    const SizedBox(height: 12),
                    AppointmentSummary(appointment: appointment),
                    const SizedBox(height: 20),
                    ..._actions(appointment),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _actions(Appointment a) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final widgets = <Widget>[];

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Text(text, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        );

    // Booking status
    if (a.status == AppointmentStatus.pending || a.status == AppointmentStatus.confirmed) {
      widgets.add(heading('Booking'));
      if (a.status == AppointmentStatus.pending) {
        widgets.add(FilledButton.icon(
          onPressed: _busy ? null : () => _setStatus(a, 'confirmed', 'Booking confirmed'),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Confirm booking'),
        ));
      } else {
        widgets.add(FilledButton.icon(
          onPressed: _busy ? null : () => _setStatus(a, 'completed', 'Booking marked as completed'),
          icon: const Icon(Icons.task_alt),
          label: const Text('Mark as completed'),
        ));
      }
      widgets.add(const SizedBox(height: 10));
      widgets.add(OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: scheme.error, side: BorderSide(color: scheme.error)),
        onPressed: _busy ? null : () => _setStatus(a, 'cancelled', 'Booking cancelled', confirm: true),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Cancel booking'),
      ));
      widgets.add(const SizedBox(height: 20));
    }

    // Payment verification
    if (a.status != AppointmentStatus.cancelled) {
      widgets.add(heading('Payment: ${a.paymentStatus.label}'));
      if (a.paymentStatus != PaymentStatus.paid) {
        widgets.add(FilledButton.tonalIcon(
          onPressed: _busy ? null : () => _setPayment(a, 'paid', 'Payment marked as received'),
          icon: const Icon(Icons.verified_outlined),
          label: Text(a.paymentStatus == PaymentStatus.submitted ? 'Verify payment (received)' : 'Mark payment as received'),
        ));
      }
      if (a.paymentStatus == PaymentStatus.submitted) {
        widgets.add(const SizedBox(height: 10));
        widgets.add(OutlinedButton.icon(
          onPressed: _busy ? null : () => _setPayment(a, 'failed', 'Payment marked as failed'),
          icon: const Icon(Icons.error_outline),
          label: const Text('Could not verify payment'),
        ));
      }
      if (a.paymentStatus == PaymentStatus.paid) {
        widgets.add(TextButton.icon(
          onPressed: _busy ? null : () => _setPayment(a, 'unpaid', 'Payment marked as unpaid'),
          icon: const Icon(Icons.undo),
          label: const Text('Mark as unpaid'),
        ));
      }
    }
    return widgets;
  }
}
