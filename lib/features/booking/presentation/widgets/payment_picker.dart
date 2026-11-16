import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/payment_method.dart';

/// Lists the payment options an admin enabled. Wallet-style options (bKash, Nagad, ...)
/// show the instructions and ask for the transaction ID.
class PaymentPicker extends StatelessWidget {
  const PaymentPicker({
    super.key,
    required this.methods,
    required this.selected,
    required this.onSelected,
    required this.referenceController,
    required this.onRetry,
    this.enabled = true,
  });

  final AsyncValue<List<PaymentMethod>> methods;
  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod> onSelected;
  final TextEditingController referenceController;
  final VoidCallback onRetry;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return methods.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Row(
        children: [
          Expanded(child: Text(error is ApiException ? error.message : 'Could not load payment options.')),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No payment options are available right now. Please try again later.'),
          );
        }
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final m in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: selected?.id == m.id
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: enabled ? () => onSelected(m) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            m.type.icon,
                            color: selected?.id == m.id ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                Text(
                                  m.type.label,
                                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            selected?.id == m.id ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: selected?.id == m.id ? scheme.primary : scheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (selected != null && (selected!.instructions?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selected!.instructions!,
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            if (selected?.requiresReference ?? false)
              AppTextField(
                controller: referenceController,
                label: '${selected!.name} transaction ID',
                hint: 'e.g. 9A7XK21LMP',
                prefixIcon: Icons.receipt_long_outlined,
                enabled: enabled,
                validator: (v) =>
                    (v == null || v.trim().length < 4) ? 'Enter the transaction ID after sending the money' : null,
              ),
          ],
        );
      },
    );
  }
}
