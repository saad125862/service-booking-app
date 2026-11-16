import '../../../core/network/api_client.dart';
import '../../booking/domain/appointment.dart';
import '../../booking/domain/payment_method.dart';
import '../../discounts/domain/discount_request.dart';
import '../domain/admin_service.dart';
import '../domain/dashboard.dart';
import '../domain/sales_report.dart';

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

  // ------------------------------------------------------------------ services
  Future<List<AdminService>> services({String? search, String status = 'all'}) async {
    final res = await _api.get(
      '/admin/services',
      query: {if (search != null && search.trim().isNotEmpty) 'search': search.trim(), 'status': status, 'limit': 100},
    );
    return [for (final s in res.data as List) AdminService.fromJson(s as Map<String, dynamic>)];
  }

  Future<AdminService> service(String id) async {
    final res = await _api.get('/admin/services/$id');
    return AdminService.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminService> createService(Map<String, dynamic> body) async {
    final res = await _api.post('/admin/services', data: body);
    return AdminService.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminService> updateService(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/admin/services/$id', data: body);
    return AdminService.fromJson(res.data as Map<String, dynamic>);
  }

  /// Hides a service from customers (never a hard delete) or shows it again.
  Future<AdminService> setServiceActive(String id, bool active) async {
    final res = active
        ? await _api.patch('/admin/services/$id', data: {'isActive': true})
        : await _api.delete('/admin/services/$id');
    return AdminService.fromJson(res.data as Map<String, dynamic>);
  }

  // ------------------------------------------------------------ custom fields
  Future<List<ServiceField>> fields() async {
    final res = await _api.get('/admin/service-fields');
    return [for (final f in res.data as List) ServiceField.fromJson(f as Map<String, dynamic>)];
  }

  Future<ServiceField> createField(Map<String, dynamic> body) async {
    final res = await _api.post('/admin/service-fields', data: body);
    return ServiceField.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ServiceField> updateField(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/admin/service-fields/$id', data: body);
    return ServiceField.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ServiceField> setFieldActive(String id, bool active) async {
    final res = active
        ? await _api.patch('/admin/service-fields/$id', data: {'isActive': true})
        : await _api.delete('/admin/service-fields/$id');
    return ServiceField.fromJson(res.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------- payment methods
  Future<List<PaymentMethod>> paymentMethods() async {
    final res = await _api.get('/admin/payment-methods');
    return [for (final m in res.data as List) PaymentMethod.fromJson(m as Map<String, dynamic>)];
  }

  Future<PaymentMethod> createPaymentMethod(Map<String, dynamic> body) async {
    final res = await _api.post('/admin/payment-methods', data: body);
    return PaymentMethod.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PaymentMethod> updatePaymentMethod(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/admin/payment-methods/$id', data: body);
    return PaymentMethod.fromJson(res.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------- discount requests
  /// [status] is pending | approved | declined | used, or null for all.
  Future<List<DiscountRequest>> discountRequests({String? status}) async {
    final res = await _api.get('/admin/discount-requests', query: {'status': ?status, 'limit': 50});
    return [for (final r in res.data as List) DiscountRequest.fromJson(r as Map<String, dynamic>)];
  }

  /// [type] is percent | fixed.
  Future<DiscountRequest> approveDiscount(
    String id, {
    required String type,
    required num value,
    int expiresInDays = 14,
    String? note,
  }) async {
    final res = await _api.patch(
      '/admin/discount-requests/$id/approve',
      data: {
        'type': type,
        'value': value,
        'expiresInDays': expiresInDays,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return DiscountRequest.fromJson(res.data as Map<String, dynamic>);
  }

  Future<DiscountRequest> declineDiscount(String id, {String? note}) async {
    final res = await _api.patch(
      '/admin/discount-requests/$id/decline',
      data: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
    );
    return DiscountRequest.fromJson(res.data as Map<String, dynamic>);
  }

  // ------------------------------------------------------------------ reports
  /// [from] / [to] are `YYYY-MM-DD`; [groupBy] is day | service | category | payment.
  Future<SalesReport> salesReport({required String from, required String to, required String groupBy}) async {
    final res = await _api.get('/admin/reports/sales', query: {'from': from, 'to': to, 'groupBy': groupBy});
    return SalesReport.fromJson(res.data as Map<String, dynamic>);
  }

  // ------------------------------------------------------------------ bookings
  Future<BookingsPage> bookings({
    String? status,
    String? paymentStatus,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get(
      '/admin/appointments',
      query: {
        'status': ?status,
        'paymentStatus': ?paymentStatus,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'page': page,
        'limit': limit,
      },
    );
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
