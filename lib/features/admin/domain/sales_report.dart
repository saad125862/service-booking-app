/// One group in a sales report (a day, a service, a category or a payment method).
class ReportRow {
  const ReportRow({required this.key, required this.bookings, required this.revenue, required this.discounts});

  final String key;
  final int bookings;
  final double revenue;
  final double discounts;

  factory ReportRow.fromJson(Map<String, dynamic> json) => ReportRow(
    key: '${json['key']}',
    bookings: (json['bookings'] as num).toInt(),
    revenue: (json['revenue'] as num).toDouble(),
    discounts: (json['discounts'] as num? ?? 0).toDouble(),
  );
}

class ReportSummary {
  const ReportSummary({
    required this.revenue,
    required this.bookings,
    required this.averageOrderValue,
    required this.discountsGiven,
    required this.paidAmount,
    required this.unpaidAmount,
    required this.cancelledBookings,
    required this.pendingBookings,
  });

  final double revenue;
  final int bookings;
  final double averageOrderValue;
  final double discountsGiven;
  final double paidAmount;
  final double unpaidAmount;
  final int cancelledBookings;
  final int pendingBookings;

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
    revenue: (json['revenue'] as num).toDouble(),
    bookings: (json['bookings'] as num).toInt(),
    averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
    discountsGiven: (json['discountsGiven'] as num).toDouble(),
    paidAmount: (json['paidAmount'] as num).toDouble(),
    unpaidAmount: (json['unpaidAmount'] as num).toDouble(),
    cancelledBookings: (json['cancelledBookings'] as num).toInt(),
    pendingBookings: (json['pendingBookings'] as num).toInt(),
  );
}

/// Sales (confirmed + completed bookings) over a date range, grouped one way.
class SalesReport {
  const SalesReport({
    required this.from,
    required this.to,
    required this.groupBy,
    required this.groupLabel,
    required this.summary,
    required this.rows,
  });

  /// `YYYY-MM-DD` in the business time zone.
  final String from;
  final String to;
  final String groupBy;
  final String groupLabel;
  final ReportSummary summary;
  final List<ReportRow> rows;

  factory SalesReport.fromJson(Map<String, dynamic> json) => SalesReport(
    from: json['from'] as String,
    to: json['to'] as String,
    groupBy: json['groupBy'] as String,
    groupLabel: json['groupLabel'] as String,
    summary: ReportSummary.fromJson(json['summary'] as Map<String, dynamic>),
    rows: [for (final r in json['rows'] as List) ReportRow.fromJson(r as Map<String, dynamic>)],
  );

  /// The same CSV the API's `/reports/sales.csv` produces, built here so it can be copied.
  String toCsv() {
    String cell(Object v) {
      final s = '$v';
      return RegExp(r'[",\n]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
    }

    final lines = <List<Object>>[
      [groupLabel, 'Bookings', 'Revenue (BDT)', 'Discounts (BDT)'],
      for (final r in rows) [r.key, r.bookings, r.revenue, r.discounts],
      ['Total', summary.bookings, summary.revenue, summary.discountsGiven],
    ];
    return lines.map((l) => l.map(cell).join(',')).join('\n');
  }
}
