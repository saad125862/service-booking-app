import 'package:flutter/material.dart';

import '../../features/booking/domain/appointment.dart';

/// Coloured pill showing an appointment's status (icon + text, never colour alone).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.large = false});

  final AppointmentStatus status;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: large ? 14 : null,
        );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 6 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: large ? 18 : 14, color: color),
          const SizedBox(width: 4),
          Text(status.label, style: style),
        ],
      ),
    );
  }
}
