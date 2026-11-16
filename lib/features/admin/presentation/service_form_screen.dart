import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_banner.dart';
import '../domain/admin_service.dart';
import 'admin_providers.dart';
import 'widgets/dynamic_fields_form.dart';
import 'widgets/field_editor_dialog.dart';
import 'widgets/photo_field.dart';

/// Add a service (`serviceId == null`) or edit one. The "Extra details" section is dynamic:
/// it shows the custom fields admins have defined, and new ones can be added right here.
class ServiceFormScreen extends ConsumerWidget {
  const ServiceFormScreen({super.key, this.serviceId});

  final String? serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fields = ref.watch(adminFieldsProvider);
    final existing = serviceId == null ? null : ref.watch(adminServiceProvider(serviceId!));

    Widget scaffold(Widget body) => Scaffold(
      appBar: AppBar(
        title: Text(serviceId == null ? 'Add service' : 'Edit service'),
        leading: BackButton(onPressed: () => _leave(context)),
      ),
      body: body,
    );

    final error = fields.error ?? existing?.error;
    if (error != null && !(fields.isLoading || (existing?.isLoading ?? false))) {
      return scaffold(
        ErrorView(
          message: error is ApiException ? error.message : 'Please try again.',
          onRetry: () {
            ref.invalidate(adminFieldsProvider);
            if (serviceId != null) ref.invalidate(adminServiceProvider(serviceId!));
          },
        ),
      );
    }
    if (!fields.hasValue || (existing != null && !existing.hasValue)) {
      return scaffold(const LoadingView());
    }
    return _ServiceForm(key: ValueKey(serviceId ?? 'new'), existing: existing?.requireValue);
  }
}

void _leave(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/admin/services');
  }
}

class _ServiceForm extends ConsumerStatefulWidget {
  const _ServiceForm({super.key, this.existing});

  final AdminService? existing;

  @override
  ConsumerState<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends ConsumerState<_ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _dynamicKey = GlobalKey<DynamicFieldsFormState>();

  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  late final _price = TextEditingController(text: _num(widget.existing?.price));
  late final _duration = TextEditingController(text: _num(widget.existing?.durationMinutes));
  late final _category = TextEditingController(text: widget.existing?.category ?? '');
  late PhotoChoice _photo = PhotoChoice(url: widget.existing?.imageUrl);
  late bool _featured = widget.existing?.isFeatured ?? false;
  late bool _active = widget.existing?.isActive ?? true;

  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  static String _num(num? v) => v == null ? '' : (v % 1 == 0 ? '${v.toInt()}' : '$v');

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _duration, _category]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addField() async {
    final added = await showFieldEditor(context);
    if (added != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${added.label}" added to the form')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(adminRepositoryProvider);

      // A photo chosen from the device is uploaded now; the service then points to its link.
      final photoUrl = _photo.picked != null ? await repo.uploadImage(_photo.picked!) : (_photo.url ?? '');

      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'price': num.parse(_price.text.trim()),
        'durationMinutes': int.parse(_duration.text.trim()),
        'category': _category.text.trim(),
        'imageUrl': photoUrl,
        'isFeatured': _featured,
        'isActive': _active,
        'attributes': _dynamicKey.currentState?.values() ?? const <String, dynamic>{},
      };

      final saved = _editing ? await repo.updateService(widget.existing!.id, body) : await repo.createService(body);
      ref.invalidate(adminServicesProvider);
      ref.invalidate(adminServiceProvider(saved.id));
      ref.invalidate(adminDashboardProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_editing ? 'Service updated' : '"${saved.name}" added')));
      _leave(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.details.isNotEmpty ? e.details.values.join('\n') : e.message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _requiredText(String? v, String label) => (v == null || v.trim().isEmpty) ? 'Enter the $label' : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allFields = ref.watch(adminFieldsProvider).value ?? const <ServiceField>[];
    final active = allFields.where((f) => f.isActive).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final categories =
        ref.watch(adminServicesProvider((search: '', status: 'all'))).value?.map((s) => s.category).toSet().toList() ??
        const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit service' : 'Add service'),
        leading: BackButton(onPressed: () => _leave(context)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            // A Column in a scroll view (not a lazy ListView) so every field stays built: validation
            // and the typed custom-field values must survive scrolling.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[StatusBanner(message: _error!), const SizedBox(height: 16)],
                  Text('Basics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _name,
                    label: 'Service name *',
                    enabled: !_saving,
                    maxLength: 120,
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Name must be at least 2 characters' : null,
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _description,
                    label: 'Description *',
                    enabled: !_saving,
                    maxLines: 4,
                    maxLength: 2000,
                    validator: (v) =>
                        (v == null || v.trim().length < 10) ? 'Describe the service in at least 10 characters' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _price,
                          label: 'Price (৳) *',
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            final n = num.tryParse((v ?? '').trim());
                            if (n == null) return 'Enter a price';
                            return n < 0 ? 'Cannot be negative' : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _duration,
                          label: 'Duration (min) *',
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim());
                            if (n == null) return 'Enter minutes';
                            return n < 5 || n > 480 ? '5 to 480' : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _category,
                    label: 'Category *',
                    hint: 'e.g. Wellness',
                    enabled: !_saving,
                    maxLength: 60,
                    validator: (v) => _requiredText(v, 'category'),
                  ),
                  if (categories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final c in categories)
                            ActionChip(
                              label: Text(c),
                              visualDensity: VisualDensity.compact,
                              onPressed: _saving ? null : () => setState(() => _category.text = c),
                            ),
                        ],
                      ),
                    ),
                  PhotoField(choice: _photo, enabled: !_saving, onChanged: (c) => setState(() => _photo = c)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Featured'),
                    subtitle: const Text('Shown at the top of the customer catalog'),
                    value: _featured,
                    onChanged: _saving ? null : (v) => setState(() => _featured = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Visible to customers'),
                    subtitle: const Text('Turn off to hide it without deleting'),
                    value: _active,
                    onChanged: _saving ? null : (v) => setState(() => _active = v),
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Extra details',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _saving ? null : () => context.go('/admin/fields'),
                        icon: const Icon(Icons.tune_outlined, size: 18),
                        label: const Text('Manage'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'These fields come from your custom field list. Customers see the ones you fill in.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  DynamicFieldsForm(
                    key: _dynamicKey,
                    fields: active,
                    initialValues: widget.existing?.attributeValues ?? const {},
                    enabled: !_saving,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _addField,
                      icon: const Icon(Icons.add),
                      label: const Text('Add a field'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: _editing ? 'Save changes' : 'Add service',
                    icon: Icons.check,
                    loading: _saving,
                    onPressed: _save,
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
