import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../shell/shell_scope.dart';
import '../domain/dashboard.dart';
import '../domain/sales_report.dart';
import 'admin_providers.dart';
import 'widgets/admin_charts.dart';

/// Today's date in the business time zone (Asia/Dhaka is UTC+6, no daylight saving).
DateTime businessToday([DateTime? now]) {
  final d = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 6));
  return DateTime(d.year, d.month, d.day);
}

String _ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

enum _Preset {
  days7('Last 7 days'),
  days30('Last 30 days'),
  thisMonth('This month'),
  lastMonth('Last month'),
  custom('Custom');

  const _Preset(this.label);
  final String label;
}

const _groups = [('day', 'By day'), ('service', 'By service'), ('category', 'By category'), ('payment', 'By payment')];

/// Sales over a date range, grouped by day, service, category or payment method.
/// Sales = confirmed + completed bookings (the price after discounts).
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key, this.today});

  /// Overridable for tests.
  final DateTime? today;

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  late final DateTime _today = widget.today ?? businessToday();
  _Preset _preset = _Preset.days30;
  late DateTimeRange _range = _rangeFor(_Preset.days30);
  String _groupBy = 'day';

  DateTimeRange _rangeFor(_Preset p) {
    switch (p) {
      case _Preset.days7:
        return DateTimeRange(start: _today.subtract(const Duration(days: 6)), end: _today);
      case _Preset.thisMonth:
        return DateTimeRange(start: DateTime(_today.year, _today.month, 1), end: _today);
      case _Preset.lastMonth:
        return DateTimeRange(
          start: DateTime(_today.year, _today.month - 1, 1),
          end: DateTime(_today.year, _today.month, 0),
        );
      case _Preset.days30:
      case _Preset.custom:
        return DateTimeRange(start: _today.subtract(const Duration(days: 29)), end: _today);
    }
  }

  Future<void> _pick(_Preset p) async {
    if (p != _Preset.custom) {
      setState(() {
        _preset = p;
        _range = _rangeFor(p);
      });
      return;
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(_today.year - 3),
      lastDate: _today,
      initialDateRange: _range,
    );
    if (picked != null && mounted) {
      setState(() {
        _preset = _Preset.custom;
        _range = picked;
      });
    }
  }

  ReportQuery get _query => (from: _ymd(_range.start), to: _ymd(_range.end), groupBy: _groupBy);

  Future<void> _copyCsv(SalesReport report) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: report.toCsv()));
    messenger.showSnackBar(const SnackBar(content: Text('CSV copied. Paste it into a spreadsheet.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final report = ref.watch(adminSalesReportProvider(_query));
    final fmt = DateFormat('d MMM y');

    final Widget body = report.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e is ApiException ? e.message : 'Please try again.',
        onRetry: () => ref.invalidate(adminSalesReportProvider),
      ),
      data: (r) => _ReportBody(report: r, onCopy: () => _copyCsv(r)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales reports'),
        leading: shellMenuLeading(context),
        actions: const [NotificationBell()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  children: [
                    for (final p in _Preset.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: p == _Preset.custom ? const Icon(Icons.date_range, size: 18) : null,
                          label: Text(p.label),
                          selected: _preset == p,
                          showCheckmark: false,
                          onSelected: (_) => _pick(p),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final (value, label) in _groups)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(label),
                          selected: _groupBy == value,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _groupBy = value),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${fmt.format(_range.start)} – ${fmt.format(_range.end)} · Asia/Dhaka',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              if (report.isLoading && report.hasValue) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminSalesReportProvider);
                    try {
                      await ref.read(adminSalesReportProvider(_query).future);
                    } catch (_) {}
                  },
                  child: report.hasValue
                      ? body
                      : LayoutBuilder(
                          builder: (_, c) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(height: c.maxHeight, child: body),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report, required this.onCopy});

  final SalesReport report;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = report.summary;
    final isDay = report.groupBy == 'day';
    final rows = report.rows;
    final shown = isDay ? rows : rows.where((r) => r.bookings > 0).toList();

    String bookingsText(int n) => '$n booking${n == 1 ? '' : 's'}';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 640 ? 3 : 2;
            final w = (c.maxWidth - 12 * (cols - 1)) / cols;
            Widget tile(IconData icon, String label, String value, [String? note]) => SizedBox(
              width: w,
              child: StatCard(icon: icon, label: label, value: value, note: note),
            );
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                tile(Icons.payments_outlined, 'Revenue', Formatters.price(s.revenue), bookingsText(s.bookings)),
                tile(Icons.receipt_long_outlined, 'Average booking', Formatters.price(s.averageOrderValue)),
                tile(Icons.local_offer_outlined, 'Discounts given', Formatters.price(s.discountsGiven)),
                tile(Icons.verified_outlined, 'Paid', Formatters.price(s.paidAmount)),
                tile(Icons.hourglass_top_rounded, 'Not yet paid', Formatters.price(s.unpaidAmount)),
                tile(Icons.event_busy_outlined, 'Cancelled', '${s.cancelledBookings}', '${s.pendingBookings} pending'),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        if (s.bookings == 0)
          const SizedBox(
            height: 300,
            child: EmptyView(
              icon: Icons.bar_chart_outlined,
              title: 'No sales in this period',
              message: 'Confirmed and completed bookings in the range appear here.',
            ),
          )
        else ...[
          if (isDay && rows.length <= 31) ...[
            Text('Revenue per day', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            DailySalesChart(
              daily: [
                for (final r in rows) DailySales(date: DateTime.parse(r.key), bookings: r.bookings, revenue: r.revenue),
              ],
            ),
          ] else if (!isDay) ...[
            Text(
              'Revenue ${report.groupLabel.toLowerCase().startsWith('payment') ? 'by payment method' : 'by ${report.groupLabel.toLowerCase()}'}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            HorizontalBars(
              rows: [
                for (final r in shown)
                  (r.key, r.revenue, '${Formatters.price(r.revenue)} · ${bookingsText(r.bookings)}'),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Copy CSV'),
              ),
            ],
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _TableRow(report.groupLabel, 'Bookings', 'Revenue', 'Discounts', header: true),
                  for (final r in shown)
                    _TableRow(
                      isDay ? DateFormat('EEE, d MMM').format(DateTime.parse(r.key)) : r.key,
                      '${r.bookings}',
                      Formatters.price(r.revenue),
                      r.discounts == 0 ? '–' : Formatters.price(r.discounts),
                    ),
                  Divider(color: scheme.outlineVariant),
                  _TableRow(
                    'Total',
                    '${s.bookings}',
                    Formatters.price(s.revenue),
                    Formatters.price(s.discountsGiven),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow(this.a, this.b, this.c, this.d, {this.header = false, this.bold = false});

  final String a, b, c, d;
  final bool header;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = (header ? theme.textTheme.labelMedium : theme.textTheme.bodyMedium)?.copyWith(
      fontWeight: header || bold ? FontWeight.w800 : FontWeight.w500,
      color: header ? theme.colorScheme.onSurfaceVariant : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(a, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(b, style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            flex: 3,
            child: Text(c, style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            flex: 3,
            child: Text(d, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
