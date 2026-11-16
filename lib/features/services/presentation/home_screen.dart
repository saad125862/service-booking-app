import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/service.dart';
import 'services_providers.dart';
import 'widgets/category_chips.dart';
import 'widgets/featured_service_card.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/service_list_tile.dart';

/// Home tab: search, category chips, featured carousel and the paginated service list.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      ref.read(serviceListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // refreshes the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(serviceFiltersProvider.notifier).setSearch(value);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    ref.read(serviceFiltersProvider.notifier).setSearch('');
    setState(() {});
  }

  Future<void> _refresh() async {
    ref.invalidate(featuredServicesProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(serviceListProvider);
    try {
      await ref.read(serviceListProvider.future);
    } catch (_) {
      // The error state is rendered by the list itself.
    }
  }

  void _open(Service service) => context.push('/service/${service.id}', extra: service);

  @override
  Widget build(BuildContext context) {
    // Keep the search box in sync when filters are cleared from elsewhere.
    ref.listen(serviceFiltersProvider.select((f) => f.search), (_, next) {
      if (_search.text.trim() != next) _search.text = next;
    });

    final theme = Theme.of(context);
    final filters = ref.watch(serviceFiltersProvider);
    final list = ref.watch(serviceListProvider);
    final firstName = ref.watch(authProvider).value?.name.trim().split(' ').first ?? '';
    final sortOrPriceActive = filters.sort.index != 0 || filters.hasPriceFilter;

    final Widget listBody;
    if (list.hasError && !list.isLoading) {
      final error = list.error;
      listBody = SliverToBoxAdapter(
        child: SizedBox(
          height: 360,
          child: ErrorView(
            message: error is ApiException ? error.message : 'Please try again.',
            onRetry: () => ref.invalidate(serviceListProvider),
          ),
        ),
      );
    } else if (!list.hasValue) {
      listBody = const SliverToBoxAdapter(
        child: SizedBox(height: 320, child: LoadingView(message: 'Loading services...')),
      );
    } else if (list.requireValue.items.isEmpty) {
      listBody = SliverToBoxAdapter(
        child: SizedBox(
          height: 360,
          child: EmptyView(
            icon: Icons.search_off,
            title: 'No services found',
            message: filters.isActive
                ? 'Try a different search or clear the filters.'
                : 'There are no services available right now.',
            actionLabel: filters.isActive ? 'Clear filters' : null,
            onAction: filters.isActive ? ref.read(serviceFiltersProvider.notifier).clear : null,
          ),
        ),
      );
    } else {
      final data = list.requireValue;
      listBody = SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 520,
            mainAxisExtent: 124,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => ServiceListTile(service: data.items[i], onTap: () => _open(data.items[i])),
            childCount: data.items.length,
          ),
        ),
      );
    }

    final loadedList = list.value;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  toolbarHeight: 72,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName.isEmpty ? 'Hello' : 'Hello, $firstName',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'What do you need today?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: _onSearchChanged,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search services',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      icon: const Icon(Icons.close),
                                      onPressed: _clearSearch,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Badge(
                          isLabelVisible: sortOrPriceActive,
                          smallSize: 10,
                          child: IconButton.filledTonal(
                            tooltip: 'Sort and filter',
                            style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
                            icon: const Icon(Icons.tune),
                            onPressed: () => showFilterSheet(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: CategoryChips()),
                if (!filters.isActive) const SliverToBoxAdapter(child: _FeaturedSection()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            filters.isActive ? 'Results' : 'All services',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (loadedList != null)
                          Text(
                            '${loadedList.total} ${loadedList.total == 1 ? 'service' : 'services'}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
                if (list.isLoading && list.hasValue)
                  const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
                listBody,
                if (loadedList != null) SliverToBoxAdapter(child: _ListFooter(state: loadedList)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedSection extends ConsumerWidget {
  const _FeaturedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredServicesProvider);
    final theme = Theme.of(context);

    // Non-critical: stay silent while loading or if it fails; the main list reports problems.
    final items = featured.value ?? const <Service>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 6),
              Text('Featured', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => FeaturedServiceCard(
              service: items[i],
              onTap: () => context.push('/service/${items[i].id}', extra: items[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListFooter extends ConsumerWidget {
  const _ListFooter({required this.state});

  final ServiceListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3))),
      );
    }
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(state.loadMoreError!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
              onPressed: () => ref.read(serviceListProvider.notifier).loadMore(),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
