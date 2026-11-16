import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/state_views.dart';
import '../../booking/presentation/booking_providers.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../shell/shell_scope.dart';
import '../../booking/presentation/widgets/booking_card.dart';

/// My Bookings: upcoming and past appointments.
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My bookings'),
          leading: shellMenuLeading(context),
          actions: const [NotificationBell()],
          bottom: const TabBar(tabs: [Tab(text: 'Upcoming'), Tab(text: 'Past')]),
        ),
        body: const TabBarView(
          children: [
            _BookingList(scope: BookingScope.upcoming),
            _BookingList(scope: BookingScope.past),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends ConsumerWidget {
  const _BookingList({required this.scope});

  final BookingScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider(scope));

    return bookings.when(
      loading: () => const LoadingView(message: 'Loading bookings...'),
      error: (error, _) => ErrorView(
        message: error is ApiException ? error.message : 'Please try again.',
        onRetry: () => ref.invalidate(myBookingsProvider(scope)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return scope == BookingScope.upcoming
              ? EmptyView(
                  icon: Icons.event_available_outlined,
                  title: 'No upcoming bookings',
                  message: 'Find a service and book your first appointment.',
                  actionLabel: 'Browse services',
                  onAction: () => context.go('/'),
                )
              : const EmptyView(
                  icon: Icons.history,
                  title: 'No past bookings',
                  message: 'Completed and cancelled bookings will appear here.',
                );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myBookingsProvider(scope));
            try {
              await ref.read(myBookingsProvider(scope).future);
            } catch (_) {}
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => Reveal(
                  index: i,
                  child: PressScale(
                    child: BookingCard(
                      appointment: items[i],
                      onTap: () => context.push('/booking/${items[i].id}', extra: items[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
