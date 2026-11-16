import '../../../core/network/api_client.dart';
import '../../booking/domain/appointment.dart';
import '../domain/dashboard.dart';

/// A page of bookings.
class BookingsPage {
  const BookingsPage({required this.items, required this.page, required this.totalPages, required this.total});

  final List<Appointment> items;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;
}

/// Everything under /api/v1/admin (needs an admin account). More endpoints are added to this
/// class as the admin screens need them.
class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<DashboardData> dashboard() async {
    final res = await _api.get('/admin/dashboard');
    return DashboardData.fromJson(res.data as Map<String, dynamic>);
  }

  // ------------------------------------------------------------------ bookings
  Future<BookingsPage> bookings({
    String? status,
    String? paymentStatus,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get('/admin/appointments', query: {
      'status': ?status,
      'paymentStatus': ?paymentStatus,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'page': page,
      'limit': limit,
    });
    final meta = res.meta ?? const {};
    return BookingsPage(
      items: [for (final a in res.data as List) Appointment.fromJson(a as Map<String, dynamic>)],
      page: (meta['page'] as num?)?.toInt() ?? page,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Appointment> booking(String id) async {
    final res = await _api.get('/admin/appointments/$id');
    return Appointment.fromJson(res.data as Map<String, dynamic>);
  }

  /// [status] is confirmed | completed | cancelled.
  Future<Appointment> setStatus(String id, String status) async {
    final res = await _api.patch('/admin/appointments/$id/status', data: {'status': status});
    return Appointment.fromJson(res.data as Map<String, dynamic>);
  }

  /// [status] is paid | failed | unpaid.
  Future<Appointment> setPayment(String id, String status) async {
    final res = await _api.patch('/admin/appointments/$id/payment', data: {'status': status});
    return Appointment.fromJson(res.data as Map<String, dynamic>);
  }
}
