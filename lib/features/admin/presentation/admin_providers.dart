import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../booking/domain/appointment.dart';
import '../data/admin_repository.dart';
import '../domain/dashboard.dart';

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository(ref.watch(apiClientProvider)));

final adminDashboardProvider = FutureProvider.autoDispose<DashboardData>(
  (ref) => ref.read(adminRepositoryProvider).dashboard(),
);

// ----------------------------------------------------------------- bookings
class AdminBookingFilters {
  const AdminBookingFilters({this.status, this.paymentStatus, this.search = ''});

  final String? status;
  final String? paymentStatus;
  final String search;

  AdminBookingFilters copyWith({
    String? Function()? status,
    String? Function()? paymentStatus,
    String? search,
  }) =>
      AdminBookingFilters(
        status: status != null ? status() : this.status,
        paymentStatus: paymentStatus != null ? paymentStatus() : this.paymentStatus,
        search: search ?? this.search,
      );

  bool get isActive => status != null || paymentStatus != null || search.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is AdminBookingFilters &&
      other.status == status &&
      other.paymentStatus == paymentStatus &&
      other.search == search;

  @override
  int get hashCode => Object.hash(status, paymentStatus, search);
}

class AdminBookingFiltersNotifier extends Notifier<AdminBookingFilters> {
  @override
  AdminBookingFilters build() => const AdminBookingFilters();

  void setStatus(String? value) => state = state.copyWith(status: () => value);
  void setPaymentStatus(String? value) => state = state.copyWith(paymentStatus: () => value);
  void setSearch(String value) {
    if (value != state.search) state = state.copyWith(search: value);
  }

  void clear() => state = const AdminBookingFilters();
}

final adminBookingFiltersProvider =
    NotifierProvider<AdminBookingFiltersNotifier, AdminBookingFilters>(AdminBookingFiltersNotifier.new);

class AdminBookingsState {
  const AdminBookingsState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<Appointment> items;
  final int page;
  final int totalPages;
  final int total;
  final bool loadingMore;
  final String? loadMoreError;

  bool get hasMore => page < totalPages;

  AdminBookingsState copyWith({
    List<Appointment>? items,
    int? page,
    int? totalPages,
    int? total,
    bool? loadingMore,
    String? Function()? loadMoreError,
  }) =>
      AdminBookingsState(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreError: loadMoreError != null ? loadMoreError() : this.loadMoreError,
      );
}

/// Bookings for the current filters (reloads when they change), with paging.
class AdminBookingsController extends AsyncNotifier<AdminBookingsState> {
  static const pageSize = 20;

  @override
  Future<AdminBookingsState> build() async {
    final f = ref.watch(adminBookingFiltersProvider);
    final page = await ref.read(adminRepositoryProvider).bookings(
          status: f.status,
          paymentStatus: f.paymentStatus,
          search: f.search,
          limit: pageSize,
        );
    return AdminBookingsState(items: page.items, page: page.page, totalPages: page.totalPages, total: page.total);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    final f = ref.read(adminBookingFiltersProvider);
    state = AsyncData(current.copyWith(loadingMore: true, loadMoreError: () => null));
    try {
      final next = await ref.read(adminRepositoryProvider).bookings(
            status: f.status,
            paymentStatus: f.paymentStatus,
            search: f.search,
            page: current.page + 1,
            limit: pageSize,
          );
      if (ref.read(adminBookingFiltersProvider) != f) return; // filters changed meanwhile
      state = AsyncData(current.copyWith(
        items: [...current.items, ...next.items],
        page: next.page,
        totalPages: next.totalPages,
        total: next.total,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (ref.read(adminBookingFiltersProvider) != f) return;
      state = AsyncData(current.copyWith(loadingMore: false, loadMoreError: () => e.message));
    }
  }
}

final adminBookingsProvider =
    AsyncNotifierProvider<AdminBookingsController, AdminBookingsState>(AdminBookingsController.new);

final adminBookingProvider = FutureProvider.autoDispose.family<Appointment, String>(
  (ref, id) => ref.read(adminRepositoryProvider).booking(id),
);

/// Reloads everything that shows bookings or sales after an admin changes one.
void refreshAdminData(WidgetRef ref, {String? bookingId}) {
  ref.invalidate(adminBookingsProvider);
  ref.invalidate(adminDashboardProvider);
  if (bookingId != null) ref.invalidate(adminBookingProvider(bookingId));
}
