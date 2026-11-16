import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/state_views.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../shell/shell_scope.dart';
import 'admin_providers.dart';
import 'widgets/admin_booking_card.dart';

/// All bookings with filters by status and payment, search and paging.
class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;

  static const _statuses = [
    (null, 'All'),
    ('pending', 'Pending'),
    ('confirmed', 'Confirmed'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
  ];
  static const _payments = [
    (null, 'Any payment'),
    ('submitted', 'Awaiting verification'),
    ('paid', 'Paid'),
    ('unpaid', 'Unpaid'),
    ('failed', 'Failed'),
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        ref.read(adminBookingsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(adminBookingFiltersProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(adminBookingFiltersProvider.select((f) => f.search), (_, next) {
      if (_search.text.trim() != next) _search.text = next;
    });
    final filters = ref.watch(adminBookingFiltersProvider);
    final bookings = ref.watch(adminBookingsProvider);
    final notifier = ref.read(adminBookingFiltersProvider.notifier);
    final theme = Theme.of(context);

    final Widget body;
    if (bookings.hasError && !bookings.isLoading) {
      final error = bookings.error;
      body = SliverToBoxAdapter(
        child: SizedBox(
          height: 320,
          child: ErrorView(
            message: error is ApiException ? error.message : 'Please try again.',
            onRetry: () => ref.invalidate(adminBookingsProvider),
          ),
        ),
      );
    } else if (!bookings.hasValue) {
      body = const SliverToBoxAdapter(child: SizedBox(height: 280, child: LoadingView()));
    } else if (bookings.requireValue.items.isEmpty) {
      body = SliverToBoxAdapter(
        child: SizedBox(
          height: 320,
          child: EmptyView(
            icon: Icons.event_busy_outlined,
            title: 'No bookings found',
            message: filters.isActive ? 'Try different filters.' : 'Bookings will appear here.',
            actionLabel: filters.isActive ? 'Clear filters' : null,
            onAction: filters.isActive ? notifier.clear : null,
          ),
        ),
      );
    } else {
      final data = bookings.requireValue;
      body = SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: data.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => AdminBookingCard(
            appointment: data.items[i],
            onTap: () => context.go('/admin/bookings/${data.items[i].id}', extra: data.items[i]),
          ),
        ),
      );
    }

    final loaded = bookings.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        leading: shellMenuLeading(context),
        actions: const [NotificationBell()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminBookingsProvider);
              try {
                await ref.read(adminBookingsProvider.future);
              } catch (_) {}
            },
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: TextField(
                      controller: _search,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Search customer, email or service',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _search.clear();
                                  notifier.setSearch('');
                                  setState(() {});
                                },
                              ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final (value, label) in _statuses)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: filters.status == value,
                              showCheckmark: false,
                              onSelected: (_) => notifier.setStatus(value),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final (value, label) in _payments)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(label),
                              selected: filters.paymentStatus == value,
                              showCheckmark: false,
                              onSelected: (_) => notifier.setPaymentStatus(value),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (loaded != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        '${loaded.total} booking${loaded.total == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                if (bookings.isLoading && bookings.hasValue) const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
                body,
                if (loaded != null && loaded.loadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
                  ),
                if (loaded?.loadMoreError != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(loaded!.loadMoreError!),
                          TextButton(onPressed: () => ref.read(adminBookingsProvider.notifier).loadMore(), child: const Text('Try again')),
                        ],
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
