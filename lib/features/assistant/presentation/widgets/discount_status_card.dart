import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../discounts/domain/discount_request.dart';
import '../../../discounts/presentation/discount_providers.dart';
import '../../../notifications/presentation/notification_providers.dart';

/// Shown under the assistant's message when the customer asked for a discount.
/// The assistant cannot grant one: an admin decides. While it is pending this card waits
/// (checking every few seconds) and, when the admin decides, shows the assistant's answer.
class DiscountStatusCard extends ConsumerStatefulWidget {
  const DiscountStatusCard({super.key, required this.requestId, this.pollInterval = const Duration(seconds: 10)});

  final String requestId;
  final Duration pollInterval;

  @override
  ConsumerState<DiscountStatusCard> createState() => _DiscountStatusCardState();
}

class _DiscountStatusCardState extends ConsumerState<DiscountStatusCard> {
  Timer? _timer;
  bool _wasPending = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Poll only while the request is pending.
  void _sync(bool pending) {
    if (pending && _timer == null) {
      _timer = Timer.periodic(widget.pollInterval, (_) => ref.invalidate(myDiscountsProvider));
    } else if (!pending && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
    if (_wasPending && !pending) {
      // Decided: the notification bell should reflect it too.
      Future.microtask(() => ref.read(unreadCountProvider.notifier).refresh());
    }
    _wasPending = pending;
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(myDiscountsProvider).value;
    final request = requests?.where((r) => r.id == widget.requestId).firstOrNull;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Until the first load, or if it is missing, assume it is still waiting for an admin.
    final pending = request == null || request.isPending;
    _sync(pending);

    if (pending) {
      return _Card(
        color: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
        leading: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
        title: 'Waiting for an admin',
        body: 'An admin is processing your discount request. I will answer here as soon as they decide.',
      );
    }

    final approved = request.status == 'approved' || request.status == 'used';
    final declined = request.status == 'declined';
    return _Card(
      color: approved ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
      foreground: approved ? scheme.onTertiaryContainer : scheme.onSurface,
      leading: Icon(
        approved ? Icons.check_circle_outline : (declined ? Icons.info_outline : Icons.schedule),
        color: approved ? scheme.onTertiaryContainer : scheme.onSurfaceVariant,
      ),
      title: approved
          ? 'Discount approved'
          : declined
          ? 'Discount not approved'
          : 'Discount ${request.status}',
      body: request.reply ?? 'The request was ${request.status}.',
      footer: approved ? _footer(request) : null,
    );
  }

  String? _footer(DiscountRequest r) {
    final parts = <String>[
      ?r.discountLabel,
      if (r.status == 'used') 'already used' else 'one order only',
      if (r.expiresAt != null && r.status != 'used')
        'valid until ${DateFormat('d MMM y').format(r.expiresAt!.toLocal())}',
    ];
    return parts.join('  ·  ');
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.color,
    required this.foreground,
    required this.leading,
    required this.title,
    required this.body,
    this.footer,
  });

  final Color color;
  final Color foreground;
  final Widget leading;
  final String title;
  final String body;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: leading),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(color: foreground, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: foreground, height: 1.4)),
                if (footer != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    footer!,
                    style: theme.textTheme.labelMedium?.copyWith(color: foreground, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
