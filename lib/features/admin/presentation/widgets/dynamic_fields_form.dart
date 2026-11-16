import 'package:flutter/material.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../domain/admin_service.dart';

/// The "dynamic" part of the add / edit service form: renders one input per custom field an
/// admin has defined (short text, long text, number, yes/no, dropdown). New fields appear here
/// as soon as they are added. Must be placed inside a [Form] so the parent can validate it.
class DynamicFieldsForm extends StatefulWidget {
  const DynamicFieldsForm({super.key, required this.fields, this.initialValues = const {}, this.enabled = true});

  /// Only the active fields.
  final List<ServiceField> fields;
  final Map<String, dynamic> initialValues;
  final bool enabled;

  @override
  State<DynamicFieldsForm> createState() => DynamicFieldsFormState();
}

class DynamicFieldsFormState extends State<DynamicFieldsForm> {
  final _controllers = <String, TextEditingController>{};
  final _choices = <String, Object?>{};

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(DynamicFieldsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(); // a newly added field gets its own input; existing inputs keep what was typed
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isTextual(ServiceField f) =>
      f.type == FieldType.text || f.type == FieldType.textarea || f.type == FieldType.number;

  void _sync() {
    for (final f in widget.fields) {
      final initial = widget.initialValues[f.key];
      if (_isTextual(f)) {
        _controllers.putIfAbsent(f.key, () {
          final v = initial;
          return TextEditingController(text: v == null ? '' : (v is num && v % 1 == 0 ? '${v.toInt()}' : '$v'));
        });
      } else if (!_choices.containsKey(f.key)) {
        if (f.type == FieldType.boolean) {
          _choices[f.key] = initial is bool ? initial : null;
        } else {
          _choices[f.key] = initial is String && f.options.contains(initial) ? initial : null;
        }
      }
    }
  }

  /// The values to send as `attributes`: empty inputs are left out.
  Map<String, dynamic> values() {
    final out = <String, dynamic>{};
    for (final f in widget.fields) {
      if (_isTextual(f)) {
        final text = _controllers[f.key]?.text.trim() ?? '';
        if (text.isEmpty) continue;
        out[f.key] = f.type == FieldType.number ? (num.tryParse(text) ?? text) : text;
      } else if (_choices[f.key] != null) {
        out[f.key] = _choices[f.key];
      }
    }
    return out;
  }

  String? _required(ServiceField f, String? value) =>
      f.required && (value == null || value.trim().isEmpty) ? '${f.label} is required' : null;

  Widget _input(ServiceField f) {
    final label = f.required ? '${f.label} *' : f.label;

    switch (f.type) {
      case FieldType.text:
      case FieldType.textarea:
        return AppTextField(
          controller: _controllers[f.key]!,
          label: label,
          maxLines: f.type == FieldType.textarea ? 3 : 1,
          maxLength: f.type == FieldType.textarea ? 2000 : 200,
          enabled: widget.enabled,
          validator: (v) => _required(f, v),
        );
      case FieldType.number:
        return AppTextField(
          controller: _controllers[f.key]!,
          label: label,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: widget.enabled,
          validator: (v) {
            final required = _required(f, v);
            if (required != null) return required;
            if (v != null && v.trim().isNotEmpty && num.tryParse(v.trim()) == null) return 'Enter a number';
            return null;
          },
        );
      case FieldType.boolean:
        return DropdownButtonFormField<bool?>(
          initialValue: _choices[f.key] as bool?,
          decoration: InputDecoration(labelText: label),
          items: const [
            DropdownMenuItem(value: null, child: Text('Not set')),
            DropdownMenuItem(value: true, child: Text('Yes')),
            DropdownMenuItem(value: false, child: Text('No')),
          ],
          onChanged: widget.enabled ? (v) => setState(() => _choices[f.key] = v) : null,
          validator: (v) => f.required && v == null ? '${f.label} is required' : null,
        );
      case FieldType.select:
        return DropdownButtonFormField<String?>(
          initialValue: _choices[f.key] as String?,
          decoration: InputDecoration(labelText: label),
          items: [
            const DropdownMenuItem(value: null, child: Text('Not set')),
            for (final o in f.options) DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: widget.enabled ? (v) => setState(() => _choices[f.key] = v) : null,
          validator: (v) => f.required && v == null ? '${f.label} is required' : null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fields.isEmpty) {
      return Text(
        'No extra fields yet. Add one if the standard fields are not enough.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final f in widget.fields) Padding(padding: const EdgeInsets.only(bottom: 14), child: _input(f))],
    );
  }
}
