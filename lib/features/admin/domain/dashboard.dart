import '../../booking/domain/appointment.dart';

class SalesPeriod {
  const SalesPeriod({required this.bookings, required this.revenue});

  final int bookings;
  final double revenue;

  factory SalesPeriod.fromJson(Map<String, dynamic> json) => SalesPeriod(
        bookings: (json['bookings'] as num).toInt(),
        revenue: ((json['revenue'] ?? json['value']) as num).toDouble(),
      );
}

class DailySales {
  const DailySales({required this.date, required this.bookings, required this.revenue});

  final DateTime date;
  final int bookings;
  final double revenue;

  factory DailySales.fromJson(Map<String, dynamic> json) => DailySales(
        date: DateTime.parse(json['date'] as String),
        bookings: (json['bookings'] as num).toInt(),
        revenue: (json['revenue'] as num).toDouble(),
      );
}

class TopService {
  const TopService({required this.name, required this.bookings, required this.revenue});

  final String name;
  final int bookings;
  final double revenue;

  factory TopService.fromJson(Map<String, dynamic> json) => TopService(
        name: json['name'] as String,
        bookings: (json['bookings'] as num).toInt(),
        revenue: (json['revenue'] as num).toDouble(),
      );
}

/// Numbers for the admin dashboard.
/// Sales = price paid for bookings that are confirmed or completed (by service date);
/// the pipeline is the value of bookings that are still pending.
class DashboardData {
  const DashboardData({
    required this.timeZone,
    required this.services,
    required this.customers,
    required this.bookings,
    required this.pendingBookings,
    required this.pendingDiscountRequests,
    required this.pendingPayments,
    required this.today,
    required this.thisMonth,
    required this.allTime,
    required this.pipeline,
    required this.byStatus,
    required this.topServices,
    required this.daily,
    required this.recentBookings,
  });

  final String timeZone;
  final int services;
  final int customers;
  final int bookings;
  final int pendingBookings;
  final int pendingDiscountRequests;
  final int pendingPayments;
  final SalesPeriod today;
  final SalesPeriod thisMonth;
  final SalesPeriod allTime;
  final SalesPeriod pipeline;
  final Map<String, int> byStatus;
  final List<TopService> topServices;
  final List<DailySales> daily;
  final List<Appointment> recentBookings;

  /// Anything an admin should act on.
  int get needsAttention => pendingBookings + pendingPayments + pendingDiscountRequests;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>;
    final sales = json['sales'] as Map<String, dynamic>;
    final byStatus = (json['byStatus'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()));
    return DashboardData(
      timeZone: json['timeZone'] as String? ?? 'UTC',
      services: (totals['services'] as num).toInt(),
      customers: (totals['customers'] as num).toInt(),
      bookings: (totals['bookings'] as num).toInt(),
      pendingBookings: (totals['pendingBookings'] as num).toInt(),
      pendingDiscountRequests: (totals['pendingDiscountRequests'] as num).toInt(),
      pendingPayments: (totals['pendingPayments'] as num).toInt(),
      today: SalesPeriod.fromJson(sales['today'] as Map<String, dynamic>),
      thisMonth: SalesPeriod.fromJson(sales['thisMonth'] as Map<String, dynamic>),
      allTime: SalesPeriod.fromJson(sales['allTime'] as Map<String, dynamic>),
      pipeline: SalesPeriod.fromJson(sales['pipeline'] as Map<String, dynamic>),
      byStatus: byStatus,
      topServices: [for (final t in json['topServices'] as List) TopService.fromJson(t as Map<String, dynamic>)],
      daily: [for (final d in json['daily'] as List) DailySales.fromJson(d as Map<String, dynamic>)],
      recentBookings: [for (final a in json['recentBookings'] as List) Appointment.fromJson(a as Map<String, dynamic>)],
    );
  }
}
