import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/dashboard.dart';

/// Revenue per day as simple bars (no chart library): the tallest bar is the best day.
class DailySalesChart extends StatelessWidget {
  const DailySalesChart({super.key, required this.daily, this.height = 150});

  final List<DailySales> daily;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final maxRevenue = daily.fold<double>(0, (m, d) => d.revenue > m ? d.revenue : m);

    if (daily.isEmpty || maxRevenue == 0) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No sales in the last ${daily.length} days yet', style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      );
    }

    return Semantics(
      label: 'Revenue over the last ${daily.length} days',
      child: SizedBox(
        height: height + 28,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < daily.length; i++)
              Expanded(
                child: Tooltip(
                  message: '${DateFormat('EEE d MMM').format(daily[i].date)}\n'
                      '${Formatters.price(daily[i].revenue)} · ${daily[i].bookings} booking${daily[i].bookings == 1 ? '' : 's'}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: daily[i].revenue == 0 ? 3 : (daily[i].revenue / maxRevenue) * height,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: daily[i].revenue == 0
                              ? scheme.outlineVariant
                              : (i == daily.length - 1 ? scheme.primary : scheme.primary.withValues(alpha: 0.55)),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${daily[i].date.day}',
                        style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Labelled horizontal bars (e.g. top services by revenue).
class HorizontalBars extends StatelessWidget {
  const HorizontalBars({super.key, required this.rows});

  /// (label, value, caption)
  final List<(String, double, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxValue = rows.fold<double>(0, (m, r) => r.$2 > m ? r.$2 : m);

    return Column(
      children: [
        for (final (label, value, caption) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Text(caption, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: maxValue == 0 ? 0 : value / maxValue,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One stat tile: icon, big number, label and a small note.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.icon, required this.label, required this.value, this.note, this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final String? note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant))),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(note!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
