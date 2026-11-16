import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../shell/shell_scope.dart';
import '../domain/dashboard.dart';
import 'admin_providers.dart';
import 'widgets/admin_booking_card.dart';
import 'widgets/admin_charts.dart';

/// Sales and activity at a glance.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: shellMenuLeading(context),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminDashboardProvider),
          ),
          const NotificationBell(),
        ],
      ),
      body: dashboard.when(
        loading: () => const LoadingView(message: 'Loading dashboard...'),
        error: (error, _) => ErrorView(
          message: error is ApiException ? error.message : 'Please try again.',
          onRetry: () => ref.invalidate(adminDashboardProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminDashboardProvider);
            try {
              await ref.read(adminDashboardProvider.future);
            } catch (_) {}
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: _Body(data: data),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 4 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _tile(
                  width,
                  StatCard(
                    icon: Icons.today_outlined,
                    label: 'Sales today',
                    value: Formatters.price(data.today.revenue),
                    amount: data.today.revenue,
                    note: '${data.today.bookings} bookings',
                  ),
                ),
                _tile(
                  width,
                  StatCard(
                    icon: Icons.calendar_view_month_outlined,
                    label: 'This month',
                    value: Formatters.price(data.thisMonth.revenue),
                    amount: data.thisMonth.revenue,
                    note: '${data.thisMonth.bookings} bookings',
                  ),
                ),
                _tile(
                  width,
                  StatCard(
                    icon: Icons.account_balance_outlined,
                    label: 'All time',
                    value: Formatters.price(data.allTime.revenue),
                    amount: data.allTime.revenue,
                    note: '${data.allTime.bookings} bookings',
                  ),
                ),
                _tile(
                  width,
                  StatCard(
                    icon: Icons.hourglass_top_rounded,
                    label: 'Pending value',
                    value: Formatters.price(data.pipeline.revenue),
                    amount: data.pipeline.revenue,
                    note: '${data.pipeline.bookings} awaiting confirmation',
                    onTap: () => context.go('/admin/bookings'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Needs your attention',
          child: data.needsAttention == 0
              ? Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: scheme.primary),
                    const SizedBox(width: 8),
                    const Text("You're all caught up."),
                  ],
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (data.pendingBookings > 0)
                      ActionChip(
                        avatar: const Icon(Icons.event_note_outlined, size: 18),
                        label: Text('${data.pendingBookings} pending booking${data.pendingBookings == 1 ? '' : 's'}'),
                        onPressed: () => context.go('/admin/bookings'),
                      ),
                    if (data.pendingPayments > 0)
                      ActionChip(
                        avatar: const Icon(Icons.receipt_long_outlined, size: 18),
                        label: Text('${data.pendingPayments} payment${data.pendingPayments == 1 ? '' : 's'} to verify'),
                        onPressed: () => context.go('/admin/bookings'),
                      ),
                    if (data.pendingDiscountRequests > 0)
                      ActionChip(
                        avatar: const Icon(Icons.local_offer_outlined, size: 18),
                        label: Text(
                          '${data.pendingDiscountRequests} discount request${data.pendingDiscountRequests == 1 ? '' : 's'}',
                        ),
                        onPressed: () => context.go('/admin/discounts'),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Revenue, last ${data.daily.length} days',
          trailing: Text(data.timeZone, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          child: DailySalesChart(daily: data.daily),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Bookings by status',
          child: _StatusBreakdown(byStatus: data.byStatus),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Top services by revenue',
          child: data.topServices.isEmpty
              ? Text(
                  'Sales will appear here once bookings are confirmed.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                )
              : HorizontalBars(
                  rows: [
                    for (final t in data.topServices)
                      (t.name, t.revenue, '${Formatters.price(t.revenue)} · ${t.bookings}×'),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Latest bookings',
          trailing: TextButton(onPressed: () => context.go('/admin/bookings'), child: const Text('See all')),
          child: data.recentBookings.isEmpty
              ? Text('No bookings yet.', style: TextStyle(color: scheme.onSurfaceVariant))
              : Column(
                  children: [
                    for (final a in data.recentBookings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AdminBookingCard(
                          appointment: a,
                          onTap: () => context.go('/admin/bookings/${a.id}', extra: a),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MiniTotal(icon: Icons.people_outline, label: 'Customers', value: data.customers),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniTotal(icon: Icons.spa_outlined, label: 'Active services', value: data.services),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniTotal(icon: Icons.event_available_outlined, label: 'All bookings', value: data.bookings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tile(double width, Widget child) => SizedBox(width: width, child: child);
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.byStatus});

  final Map<String, int> byStatus;

  static const _order = [
    ('pending', 'Pending', Color(0xFFF08C00)),
    ('confirmed', 'Confirmed', Color(0xFF2F9E44)),
    ('completed', 'Completed', Color(0xFF4C6EF5)),
    ('cancelled', 'Cancelled', Color(0xFFC92A2A)),
  ];

  @override
  Widget build(BuildContext context) {
    final total = byStatus.values.fold<int>(0, (a, b) => a + b);
    final theme = Theme.of(context);
    if (total == 0) return Text('No bookings yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant));

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (final (key, _, color) in _order)
                  if ((byStatus[key] ?? 0) > 0)
                    Expanded(
                      flex: byStatus[key]!,
                      child: Container(height: 12, color: color),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final (key, label, color) in _order)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('$label ${byStatus[key] ?? 0}', style: theme.textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _MiniTotal extends StatelessWidget {
  const _MiniTotal({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text('$value', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
