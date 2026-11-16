import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../services/presentation/widgets/service_image.dart';
import '../../domain/appointment.dart';

/// Card with everything about one appointment, shared by the confirmation and details screens.
class AppointmentSummary extends StatelessWidget {
  const AppointmentSummary({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = appointment;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: ServiceImage(url: a.service.imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.service.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(status: a.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(a.service.category, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
                const Divider(height: 28),
                _Row(icon: Icons.event_outlined, label: 'When', value: a.startLabel),
                _Row(icon: Icons.schedule, label: 'Duration', value: Formatters.duration(a.service.durationMinutes)),
                _Row(
                  icon: Icons.payments_outlined,
                  label: 'Price',
                  value: a.hasDiscount
                      ? '${Formatters.price(a.amount)} (was ${Formatters.price(a.originalPrice)})'
                      : Formatters.price(a.amount),
                ),
                if (a.hasDiscount)
                  _Row(
                    icon: Icons.local_offer_outlined,
                    label: 'Discount',
                    value: '-${Formatters.price(a.discountAmount)}',
                  ),
                _Row(
                  icon: a.paymentMethod?.type.icon ?? Icons.account_balance_wallet_outlined,
                  label: 'Payment',
                  value: '${a.paymentMethod?.name ?? 'Not selected'} · ${a.paymentStatus.label}',
                ),
                if (a.paymentReference != null && a.paymentReference!.isNotEmpty)
                  _Row(icon: Icons.receipt_long_outlined, label: 'Transaction', value: a.paymentReference!),
                if (a.address != null && a.address!.isNotEmpty)
                  _Row(icon: Icons.location_on_outlined, label: 'Address', value: a.address!),
                if (a.notes != null && a.notes!.isNotEmpty)
                  _Row(icon: Icons.notes_outlined, label: 'Notes', value: a.notes!),
                _Row(icon: Icons.tag, label: 'Reference', value: a.reference),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
