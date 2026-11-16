import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/state_views.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../shell/shell_scope.dart';
import '../domain/admin_service.dart';
import 'admin_providers.dart';
import 'widgets/field_editor_dialog.dart';

/// Manage the extra fields of the add-service form: add, rename, make required, hide.
class AdminFieldsScreen extends ConsumerWidget {
  const AdminFieldsScreen({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, ServiceField f, bool active) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepositoryProvider).setFieldActive(f.id, active);
      ref.invalidate(adminFieldsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            active ? '"${f.label}" is back on the form' : '"${f.label}" removed from the form (values are kept)',
          ),
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fields = ref.watch(adminFieldsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom fields'),
        leading: shellMenuLeading(context),
        actions: const [NotificationBell()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showFieldEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add field'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: fields.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: e is ApiException ? e.message : 'Please try again.',
              onRetry: () => ref.invalidate(adminFieldsProvider),
            ),
            data: (items) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminFieldsProvider);
                try {
                  await ref.read(adminFieldsProvider.future);
                } catch (_) {}
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  Text(
                    'Fields you add here appear on the add / edit service form, and customers see the values you fill in '
                    'on the service page. Removing a field only hides it, so existing values are never lost.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const SizedBox(
                      height: 280,
                      child: EmptyView(
                        icon: Icons.tune_outlined,
                        title: 'No custom fields yet',
                        message: 'Tap "Add field" to extend the service form.',
                      ),
                    ),
                  for (final f in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => showFieldEditor(context, existing: f),
                          child: Opacity(
                            opacity: f.isActive ? 1 : 0.6,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f.label,
                                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            _Tag(f.type.label),
                                            if (f.required) _Tag('Required', emphasized: true),
                                            if (f.type == FieldType.select) _Tag('${f.options.length} options'),
                                          ],
                                        ),
                                        if (f.type == FieldType.select && f.options.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            f.options.join(' · '),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(value: f.isActive, onChanged: (v) => _toggle(context, ref, f, v)),
                                      Text(
                                        f.isActive ? 'On form' : 'Hidden',
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

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.emphasized = false});

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: emphasized ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: emphasized ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
