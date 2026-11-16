import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/state_views.dart';
import '../../booking/domain/payment_method.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../shell/shell_scope.dart';
import 'admin_providers.dart';

/// The payment options customers can choose when booking (cash, card, bKash, Nagad, ...).
class AdminPaymentsScreen extends ConsumerWidget {
  const AdminPaymentsScreen({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, PaymentMethod m, bool active) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepositoryProvider).updatePaymentMethod(m.id, {'isActive': active});
      ref.invalidate(adminPaymentMethodsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(active ? '${m.name} is available to customers' : '${m.name} is turned off')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(adminPaymentMethodsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment options'),
        leading: shellMenuLeading(context),
        actions: const [NotificationBell()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPaymentMethodEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add option'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: methods.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: e is ApiException ? e.message : 'Please try again.',
              onRetry: () => ref.invalidate(adminPaymentMethodsProvider),
            ),
            data: (items) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminPaymentMethodsProvider);
                try {
                  await ref.read(adminPaymentMethodsProvider.future);
                } catch (_) {}
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  Text(
                    'Customers pick one of these when they book. Wallet options such as bKash ask for the transaction ID, '
                    'which you verify on the booking.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const SizedBox(
                      height: 280,
                      child: EmptyView(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'No payment options',
                        message: 'Add cash, card, bKash…',
                      ),
                    ),
                  for (final m in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => showPaymentMethodEditor(context, existing: m),
                          child: Opacity(
                            opacity: m.isActive ? 1 : 0.6,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: scheme.primaryContainer,
                                    child: Icon(m.type.icon, color: scheme.onPrimaryContainer),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.name,
                                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            m.type.label,
                                            if (m.accountNumber != null && m.accountNumber!.isNotEmpty)
                                              m.accountNumber!,
                                            if (m.requiresReference) 'asks for transaction ID',
                                          ].join(' · '),
                                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(value: m.isActive, onChanged: (v) => _toggle(context, ref, m, v)),
                                      Text(
                                        m.isActive ? 'Available' : 'Off',
                                        style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<PaymentMethod?> showPaymentMethodEditor(BuildContext context, {PaymentMethod? existing}) {
  return showDialog<PaymentMethod>(
    context: context,
    builder: (_) => _PaymentMethodDialog(existing: existing),
  );
}

class _PaymentMethodDialog extends ConsumerStatefulWidget {
  const _PaymentMethodDialog({this.existing});

  final PaymentMethod? existing;

  @override
  ConsumerState<_PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends ConsumerState<_PaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _code = TextEditingController(text: widget.existing?.code ?? '');
  late final _account = TextEditingController(text: widget.existing?.accountNumber ?? '');
  late final _instructions = TextEditingController(text: widget.existing?.instructions ?? '');
  late final _order = TextEditingController(text: '${widget.existing?.sortOrder ?? 0}');
  late PaymentType _type = widget.existing?.type ?? PaymentType.mobileWallet;
  late bool _needsReference = widget.existing?.requiresReference ?? true;
  late bool _active = widget.existing?.isActive ?? true;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    for (final c in [_name, _code, _account, _instructions, _order]) {
      c.dispose();
    }
    super.dispose();
  }

  /// "Google Pay" -> "google_pay"
  String _slug(String name) {
    final s = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    return s.length < 2
        ? 'option_${DateTime.now().millisecondsSinceEpoch % 10000}'
        : (RegExp(r'^[a-z]').hasMatch(s) ? s : 'm_$s');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(adminRepositoryProvider);
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'type': _type.apiValue,
      'accountNumber': _account.text.trim(),
      'instructions': _instructions.text.trim(),
      'requiresReference': _needsReference,
      'isActive': _active,
      'sortOrder': int.parse(_order.text.trim()),
    };
    try {
      final PaymentMethod saved;
      if (_editing) {
        saved = await repo.updatePaymentMethod(widget.existing!.id, body);
      } else {
        final code = _code.text.trim().isEmpty ? _slug(_name.text) : _code.text.trim();
        saved = await repo.createPaymentMethod({'code': code, ...body});
      }
      ref.invalidate(adminPaymentMethodsProvider);
      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.details.isNotEmpty ? e.details.values.join('\n') : e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'Edit ${widget.existing!.name}' : 'Add a payment option'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  autofocus: !_editing,
                  decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Rocket'),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                if (!_editing) ...[
                  TextFormField(
                    controller: _code,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Code (optional)',
                      helperText: 'Lower-case id such as rocket. Created from the name if left empty.',
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      return t.isEmpty || RegExp(r'^[a-z][a-z0-9_]{1,29}$').hasMatch(t)
                          ? null
                          : 'Lower-case letters, numbers and _ only';
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<PaymentType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [for (final t in PaymentType.values) DropdownMenuItem(value: t, child: Text(t.label))],
                  onChanged: _saving ? null : (t) => setState(() => _type = t ?? _type),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _account,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Account number (optional)',
                    hintText: 'Where customers send money',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instructions,
                  enabled: !_saving,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'Instructions (optional)'),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _order,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Order in the list',
                    helperText: 'Smaller numbers come first',
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n < 0 || n > 1000 ? '0 to 1000' : null;
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ask for transaction ID'),
                  value: _needsReference,
                  onChanged: _saving ? null : (v) => setState(() => _needsReference = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available to customers'),
                  value: _active,
                  onChanged: _saving ? null : (v) => setState(() => _active = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(_editing ? 'Save' : 'Add option'),
        ),
      ],
    );
  }
}
