import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/status_banner.dart';
import '../../domain/admin_service.dart';
import '../admin_providers.dart';

/// Adds a new custom field to the service form, or edits an existing one.
/// Returns the saved field, or null if cancelled.
Future<ServiceField?> showFieldEditor(BuildContext context, {ServiceField? existing}) {
  return showDialog<ServiceField>(
    context: context,
    builder: (_) => FieldEditorDialog(existing: existing),
  );
}

class FieldEditorDialog extends ConsumerStatefulWidget {
  const FieldEditorDialog({super.key, this.existing});

  final ServiceField? existing;

  @override
  ConsumerState<FieldEditorDialog> createState() => _FieldEditorDialogState();
}

class _FieldEditorDialogState extends ConsumerState<FieldEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.existing?.label ?? '');
  late final _options = TextEditingController(text: widget.existing?.options.join(', ') ?? '');
  late FieldType _type = widget.existing?.type ?? FieldType.text;
  late bool _required = widget.existing?.required ?? false;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _label.dispose();
    _options.dispose();
    super.dispose();
  }

  List<String> get _optionList =>
      _options.text.split(',').map((o) => o.trim()).where((o) => o.isNotEmpty).toSet().toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(adminRepositoryProvider);
    try {
      final ServiceField saved;
      if (_editing) {
        saved = await repo.updateField(widget.existing!.id, {
          'label': _label.text.trim(),
          'required': _required,
          if (_type == FieldType.select) 'options': _optionList,
        });
      } else {
        saved = await repo.createField({
          'label': _label.text.trim(),
          'type': _type.name,
          'required': _required,
          if (_type == FieldType.select) 'options': _optionList,
        });
      }
      ref.invalidate(adminFieldsProvider);
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
      title: Text(_editing ? 'Edit field' : 'Add a custom field'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[StatusBanner(message: _error!), const SizedBox(height: 12)],
                TextFormField(
                  controller: _label,
                  enabled: !_saving,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Field name', hintText: 'e.g. Therapist gender'),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a name (2+ characters)' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<FieldType>(
                  initialValue: _type,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    helperText: _editing ? 'The type cannot be changed once a field exists' : null,
                  ),
                  items: [for (final t in FieldType.values) DropdownMenuItem(value: t, child: Text(t.label))],
                  onChanged: _editing || _saving ? null : (t) => setState(() => _type = t ?? FieldType.text),
                ),
                if (_type == FieldType.select) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _options,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Options',
                      hintText: 'Separate with commas: Female, Male, No preference',
                    ),
                    validator: (v) => _optionList.isEmpty ? 'Add at least one option' : null,
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Required'),
                  subtitle: const Text('Admins must fill it in for every service'),
                  value: _required,
                  onChanged: _saving ? null : (v) => setState(() => _required = v),
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
              : Text(_editing ? 'Save' : 'Add field'),
        ),
      ],
    );
  }
}
