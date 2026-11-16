import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/availability.dart';

/// Time slots for the chosen day. Taken, past and too-soon slots are disabled.
class SlotGrid extends StatelessWidget {
  const SlotGrid({
    super.key,
    required this.availability,
    required this.selected,
    required this.onSelected,
    required this.onRetry,
  });

  final AsyncValue<Availability> availability;
  final TimeSlot? selected;
  final ValueChanged<TimeSlot> onSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return availability.when(
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      error: (error, _) => _Notice(
        icon: Icons.cloud_off_outlined,
        message: error is ApiException ? error.message : 'Could not load time slots.',
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
      data: (data) {
        if (data.slots.isEmpty || !data.hasAvailableSlot) {
          return const _Notice(
            icon: Icons.event_busy_outlined,
            message: 'No time slots left on this day. Try another date.',
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in data.slots)
                ChoiceChip(
                  label: Text(slot.label),
                  selected: selected == slot,
                  showCheckmark: false,
                  onSelected: slot.available ? (_) => onSelected(slot) : null,
                  labelStyle: slot.available ? null : const TextStyle(decoration: TextDecoration.lineThrough),
                  tooltip: slot.available ? null : 'Not available',
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message, this.actionLabel, this.onAction});

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
