import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../../discounts/domain/discount_request.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../shell/shell_scope.dart';
import 'admin_providers.dart';

const _filters = [
  ('pending', 'Pending'),
  ('approved', 'Approved'),
  ('declined', 'Declined'),
  ('used', 'Used'),
  (null, 'All'),
];

/// Discount requests customers made through the AI assistant. The assistant keeps the customer
/// waiting until an admin approves (with an amount) or declines here.
class AdminDiscountsScreen extends ConsumerStatefulWidget {
  const AdminDiscountsScreen({super.key});

  @override
  ConsumerState<AdminDiscountsScreen> createState() => _AdminDiscountsScreenState();
}

class _AdminDiscountsScreenState extends ConsumerState<AdminDiscountsScreen> {
  String? _status = 'pending';

  Future<void> _approve(DiscountRequest r) async {
    final done = await showDialog<bool>(
      context: context,
      builder: (_) => ApproveDiscountDialog(request: r),
    );
    if (done == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Approved. The assistant will tell the customer.')));
    }
  }

  Future<void> _decline(DiscountRequest r) async {
    final done = await showDialog<bool>(
      context: context,
      builder: (_) => DeclineDiscountDialog(request: r),
    );
    if (done == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Declined. The assistant will tell the customer.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(adminDiscountRequestsProvider(_status));

    final Widget body = requests.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e is ApiException ? e.message : 'Please try again.',
        onRetry: () => ref.invalidate(adminDiscountRequestsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyView(
            icon: Icons.local_offer_outlined,
            title: _status == 'pending' ? 'Nothing waiting' : 'No requests here',
            message: _status == 'pending'
                ? 'When a customer asks the assistant for a discount, it will show up here.'
                : 'Try another filter.',
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) =>
              _RequestCard(request: items[i], onApprove: () => _approve(items[i]), onDecline: () => _decline(items[i])),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discount requests'),
        leading: shellMenuLeading(context),
        actions: const [NotificationBell()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  children: [
                    for (final (value, label) in _filters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _status == value,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _status = value),
                        ),
                      ),
                  ],
                ),
              ),
              if (requests.isLoading && requests.hasValue) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminDiscountRequestsProvider);
                    try {
                      await ref.read(adminDiscountRequestsProvider(_status).future);
                    } catch (_) {}
                  },
                  child: requests.hasValue && requests.requireValue.isNotEmpty
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onApprove, required this.onDecline});

  final DiscountRequest request;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  (String, Color) get _statusStyle => switch (request.status) {
    'pending' => ('Pending', AppColors.warning),
    'approved' => ('Approved', AppColors.success),
    'used' => ('Used', const Color(0xFF1C7ED6)),
    'declined' => ('Declined', const Color(0xFFC92A2A)),
    _ => ('Expired', const Color(0xFF868E96)),
  };

  static const _languages = {'en': 'English', 'bn': 'বাংলা', 'banglish': 'Banglish'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = request;
    final (statusLabel, statusColor) = _statusStyle;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.customerName ?? 'Customer',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (r.customerEmail != null)
              Text(r.customerEmail!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            if (r.serviceName != null)
              Row(
                children: [
                  Icon(Icons.spa_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.servicePrice == null
                          ? r.serviceName!
                          : '${r.serviceName} · ${Formatters.price(r.servicePrice!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
              child: Text('“${r.message}”', style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            ),
            const SizedBox(height: 8),
            Text(
              '${_languages[r.language] ?? r.language} · ${Formatters.timeAgo(r.createdAt.toLocal())}',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (!r.isPending) ...[
              const Divider(height: 24),
              if (r.discountLabel != null)
                Text(
                  [
                    r.discountLabel!,
                    if (r.servicePrice != null) '(−${Formatters.price(r.amountFor(r.servicePrice!))})',
                    if (r.status == 'approved' && r.expiresAt != null)
                      'until ${Formatters.date(r.expiresAt!.toLocal())}',
                  ].join(' '),
                  style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800),
                ),
              if (r.adminNote != null && r.adminNote!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Your note: ${r.adminNote}',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              if (r.reply != null && r.reply!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Assistant told the customer',
                  style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(r.reply!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
              ],
            ],
            if (r.isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDecline,
                      icon: const Icon(Icons.close),
                      label: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Choose how much to take off (percent or taka), for how long it is valid, and an optional note.
class ApproveDiscountDialog extends ConsumerStatefulWidget {
  const ApproveDiscountDialog({super.key, required this.request});

  final DiscountRequest request;

  @override
  ConsumerState<ApproveDiscountDialog> createState() => _ApproveDiscountDialogState();
}

class _ApproveDiscountDialogState extends ConsumerState<ApproveDiscountDialog> {
  static const maxPercent = 90;

  final _formKey = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _days = TextEditingController(text: '14');
  final _note = TextEditingController();
  String _type = 'percent';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _value.dispose();
    _days.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _parsed => double.tryParse(_value.text.trim());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(adminRepositoryProvider)
          .approveDiscount(
            widget.request.id,
            type: _type,
            value: _parsed!,
            expiresInDays: int.parse(_days.text.trim()),
            note: _note.text,
          );
      ref.invalidate(adminDiscountRequestsProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.details.isNotEmpty ? e.details.values.join('\n') : e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.request;
    final price = r.servicePrice;
    final value = _parsed;
    final amount = (price != null && value != null && value > 0)
        ? (_type == 'percent' ? price * value / 100 : value).clamp(0, price).toDouble()
        : null;

    return AlertDialog(
      title: const Text('Approve discount'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${r.customerName ?? 'The customer'}${r.serviceName != null ? ' · ${r.serviceName}' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'It works for this customer only, on one booking of this service.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                  ),
                  const SizedBox(height: 12),
                ],
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'percent', label: Text('Percent %')),
                    ButtonSegment(value: 'fixed', label: Text('Amount ৳')),
                  ],
                  selected: {_type},
                  onSelectionChanged: _saving ? null : (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _value,
                  enabled: !_saving,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: _type == 'percent' ? 'Percent off' : 'Taka off',
                    helperText: _type == 'percent' ? 'Up to $maxPercent%' : null,
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    if (n == null || n <= 0) return 'Enter a number above 0';
                    if (_type == 'percent' && n > maxPercent) return 'At most $maxPercent%';
                    return null;
                  },
                ),
                if (amount != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Takes ${Formatters.price(amount)} off · customer pays ${Formatters.price(price! - amount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _days,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valid for (days)'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n < 1 || n > 90 ? '1 to 90 days' : null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _note,
                  enabled: !_saving,
                  maxLength: 300,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note for the assistant (optional)',
                    hintText: 'e.g. Regular customer, thank them',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Approve'),
        ),
      ],
    );
  }
}

class DeclineDiscountDialog extends ConsumerStatefulWidget {
  const DeclineDiscountDialog({super.key, required this.request});

  final DiscountRequest request;

  @override
  ConsumerState<DeclineDiscountDialog> createState() => _DeclineDiscountDialogState();
}

class _DeclineDiscountDialogState extends ConsumerState<DeclineDiscountDialog> {
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminRepositoryProvider).declineDiscount(widget.request.id, note: _note.text);
      ref.invalidate(adminDiscountRequestsProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Decline request'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'The assistant will politely tell the customer, in their language, that no discount is possible.',
            ),
            const SizedBox(height: 14),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _note,
              enabled: !_saving,
              maxLength: 300,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Already at our lowest price',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Decline'),
        ),
      ],
    );
  }
}
