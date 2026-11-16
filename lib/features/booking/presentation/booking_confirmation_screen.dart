import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/appointment.dart';
import 'booking_providers.dart';
import 'widgets/appointment_summary.dart';
import 'widgets/pay_online_button.dart';

/// Shown right after booking. [initial] is the appointment just created.
class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({super.key, required this.appointmentId, this.initial});

  final String appointmentId;
  final Appointment? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(appointmentDetailProvider(appointmentId));
    final appointment = detail.value ?? initial;
    final theme = Theme.of(context);

    if (appointment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: detail.hasError
            ? ErrorView(
                message: detail.error is ApiException ? (detail.error as ApiException).message : 'Please try again.',
                onRetry: () => ref.invalidate(appointmentDetailProvider(appointmentId)),
              )
            : const LoadingView(),
      );
    }

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Booking confirmed')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 44, color: AppColors.success),
                  ),
                  const SizedBox(height: 16),
                  Text("You're booked!", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    appointment.isPending
                        ? 'Your request is pending. We will confirm it shortly.'
                        : 'Your booking is ${appointment.status.label.toLowerCase()}.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppointmentSummary(appointment: appointment),
              if (appointment.canPayOnline) ...[
                const SizedBox(height: 16),
                PayOnlineButton(appointmentId: appointment.id, amount: appointment.amount),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: 'View my bookings',
                icon: Icons.calendar_month_outlined,
                onPressed: () => context.go('/bookings'),
              ),
              const SizedBox(height: 12),
              AppButton(label: 'Back to home', outlined: true, onPressed: () => context.go('/')),
            ],
          ),
        ),
      ),
    );
  }
}
