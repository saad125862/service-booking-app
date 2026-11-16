import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/state_views.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../shell/shell_scope.dart';
import '../domain/admin_service.dart';
import 'admin_providers.dart';

/// All services (including hidden ones): search, filter by visibility, add, edit and hide / show.
class AdminServicesScreen extends ConsumerStatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  ConsumerState<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends ConsumerState<AdminServicesScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _status = 'all';

  static const _statuses = [('all', 'All'), ('active', 'Visible'), ('inactive', 'Hidden')];

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _toggle(AdminService s, bool active) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepositoryProvider).setServiceActive(s.id, active);
      ref.invalidate(adminServicesProvider);
      ref.invalidate(adminDashboardProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(active ? '${s.name} is visible again' : '${s.name} is hidden from customers')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(adminServicesProvider((search: _query, status: _status)));
    final theme = Theme.of(context);

    final Widget body = services.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e is ApiException ? e.message : 'Please try again.',
        onRetry: () => ref.invalidate(adminServicesProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyView(
            icon: Icons.spa_outlined,
            title: 'No services found',
            message: _query.isNotEmpty || _status != 'all'
                ? 'Try a different search or filter.'
                : 'Add your first service.',
            actionLabel: _query.isEmpty && _status == 'all' ? 'Add service' : null,
            onAction: _query.isEmpty && _status == 'all' ? () => context.go('/admin/services/new') : null,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => Reveal(
            index: i,
            child: PressScale(
              child: _ServiceTile(
                service: items[i],
                onTap: () => context.go('/admin/services/${items[i].id}'),
                onToggle: (v) => _toggle(items[i], v),
              ),
            ),
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        leading: shellMenuLeading(context),
        actions: const [NotificationBell()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/services/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add service'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search services',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final (value, label) in _statuses)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _status == value,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _status = value),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ActionChip(
                        avatar: const Icon(Icons.tune_outlined, size: 18),
                        label: const Text('Custom fields'),
                        onPressed: () => context.go('/admin/fields'),
                      ),
                    ),
                  ],
                ),
              ),
              if (services.isLoading && services.hasValue) const LinearProgressIndicator(minHeight: 2),
              if (services.hasValue)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      '${services.requireValue.length} service${services.requireValue.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminServicesProvider);
                    try {
                      await ref.read(adminServicesProvider((search: _query, status: _status)).future);
                    } catch (_) {}
                  },
                  child: services.hasValue && services.requireValue.isNotEmpty
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

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onTap, required this.onToggle});

  final AdminService service;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = service;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: s.isActive ? 1 : 0.6,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: s.imageUrl == null
                        ? ColoredBox(
                            color: scheme.primaryContainer,
                            child: Icon(Icons.spa_outlined, color: scheme.onPrimaryContainer),
                          )
                        : Image.network(
                            s.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => ColoredBox(
                              color: scheme.primaryContainer,
                              child: Icon(Icons.spa_outlined, color: scheme.onPrimaryContainer),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.category} · ${Formatters.duration(s.durationMinutes)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            Formatters.price(s.price),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${s.bookingsCount} booked',
                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          if (s.isFeatured) Icon(Icons.star_rounded, size: 16, color: scheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(value: s.isActive, onChanged: onToggle),
                    Text(
                      s.isActive ? 'Visible' : 'Hidden',
                      style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
