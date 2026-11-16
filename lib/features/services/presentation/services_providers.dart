import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../data/service_repository.dart';
import '../domain/service.dart';
import '../domain/service_filters.dart';

final serviceRepositoryProvider =
    Provider<ServiceRepository>((ref) => ServiceRepository(ref.watch(apiClientProvider)));

/// Current search / category / sort / price filters of the home screen.
class ServiceFiltersNotifier extends Notifier<ServiceFilters> {
  @override
  ServiceFilters build() => const ServiceFilters();

  void setSearch(String value) {
    if (value != state.search) state = state.copyWith(search: value);
  }

  void setCategory(String? value) => state = state.copyWith(category: () => value);

  void apply({required ServiceSort sort, double? minPrice, double? maxPrice}) =>
      state = state.copyWith(sort: sort, minPrice: () => minPrice, maxPrice: () => maxPrice);

  void clear() => state = const ServiceFilters();
}

final serviceFiltersProvider =
    NotifierProvider<ServiceFiltersNotifier, ServiceFilters>(ServiceFiltersNotifier.new);

/// The accumulated pages shown on the home screen.
class ServiceListState {
  const ServiceListState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<Service> items;
  final int page;
  final int totalPages;
  final int total;
  final bool loadingMore;
  final String? loadMoreError;

  bool get hasMore => page < totalPages;

  ServiceListState copyWith({
    List<Service>? items,
    int? page,
    int? totalPages,
    int? total,
    bool? loadingMore,
    String? Function()? loadMoreError,
  }) =>
      ServiceListState(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreError: loadMoreError != null ? loadMoreError() : this.loadMoreError,
      );
}

/// Loads page 1 for the current filters (rebuilds whenever they change) and
/// appends further pages on demand for infinite scrolling.
class ServiceListController extends AsyncNotifier<ServiceListState> {
  static const pageSize = 12;

  @override
  Future<ServiceListState> build() async {
    final filters = ref.watch(serviceFiltersProvider);
    final page = await ref.read(serviceRepositoryProvider).list(filters: filters, limit: pageSize);
    return ServiceListState(
      items: page.items,
      page: page.page,
      totalPages: page.totalPages,
      total: page.total,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;

    final filters = ref.read(serviceFiltersProvider);
    state = AsyncData(current.copyWith(loadingMore: true, loadMoreError: () => null));
    try {
      final next = await ref
          .read(serviceRepositoryProvider)
          .list(filters: filters, page: current.page + 1, limit: pageSize);
      // Filters changed while the request was in flight: this page is stale.
      if (ref.read(serviceFiltersProvider) != filters) return;
      state = AsyncData(current.copyWith(
        items: [...current.items, ...next.items],
        page: next.page,
        totalPages: next.totalPages,
        total: next.total,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (ref.read(serviceFiltersProvider) != filters) return;
      state = AsyncData(current.copyWith(loadingMore: false, loadMoreError: () => e.message));
    }
  }
}

final serviceListProvider =
    AsyncNotifierProvider<ServiceListController, ServiceListState>(ServiceListController.new);

/// Featured services for the home carousel.
final featuredServicesProvider = FutureProvider<List<Service>>((ref) async {
  final page = await ref.read(serviceRepositoryProvider).list(featuredOnly: true, limit: 10);
  return page.items;
});

final categoriesProvider = FutureProvider<List<ServiceCategory>>(
  (ref) => ref.read(serviceRepositoryProvider).categories(),
);

final serviceDetailProvider = FutureProvider.family<Service, String>(
  (ref, id) => ref.read(serviceRepositoryProvider).detail(id),
);
