import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Number of upcoming days shown in the strip; the calendar button reaches further.
const int kDateStripDays = 14;

/// The API accepts bookings from today up to this many days ahead.
const int kMaxDaysAhead = 60;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Horizontal day picker plus a calendar button for later dates.
class DateStrip extends StatelessWidget {
  const DateStrip({super.key, required this.selected, required this.onSelected, required this.today});

  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelected;

  Future<void> _pickFromCalendar(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: today,
      lastDate: today.add(const Duration(days: kMaxDaysAhead)),
      helpText: 'Choose a date',
    );
    if (picked != null) onSelected(dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final days = [for (var i = 0; i < kDateStripDays; i++) today.add(Duration(days: i))];
    // A date chosen from the calendar that is not in the strip is shown first.
    if (!days.contains(selected)) days.insert(0, selected);

    return SizedBox(
      height: 84,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 8),
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _DayChip(
                day: days[i],
                isToday: days[i] == today,
                selected: days[i] == selected,
                onTap: () => onSelected(days[i]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.outlined(
              tooltip: 'Pick another date',
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: () => _pickFromCalendar(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.isToday, required this.selected, required this.onTap});

  final DateTime day;
  final bool isToday;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    final muted = selected ? scheme.onPrimary.withValues(alpha: 0.85) : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: DateFormat('EEEE, MMMM d').format(day),
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            width: 62,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isToday ? 'Today' : DateFormat('EEE').format(day),
                  style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${day.day}',
                  style: TextStyle(fontSize: 22, color: fg, fontWeight: FontWeight.w800),
                ),
                Text(DateFormat('MMM').format(day), style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
