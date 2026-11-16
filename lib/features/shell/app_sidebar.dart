import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/seba_logo.dart';
import '../../core/widgets/theme_mode_selector.dart';
import '../auth/domain/user.dart';
import '../auth/presentation/auth_controller.dart';
import '../auth/presentation/sign_out_dialog.dart';
import '../notifications/presentation/notification_providers.dart';
import 'nav_item.dart';

/// The left sidebar: who is signed in, navigation for their role, notifications,
/// the light/dark switch and sign out. Shown as a drawer on phones and permanently on wide screens.
class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key, this.inDrawer = false});

  final bool inDrawer;

  bool _selected(NavItem item, String path) {
    if (item.location == '/' || item.location == '/admin') return path == item.location;
    return path == item.location || path.startsWith('${item.location}/');
  }

  void _go(BuildContext context, String location, {bool push = false}) {
    if (inDrawer) Navigator.of(context).pop(); // close the drawer first
    push ? context.push(location) : context.go(location);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final unread = ref.watch(unreadCountProvider);
    final router = GoRouter.of(context);

    if (user == null) return const SizedBox.shrink();

    // Rebuild when the route changes so the highlighted item stays correct.
    return ListenableBuilder(
      listenable: router.routeInformationProvider,
      builder: (context, _) => _content(context, ref, user, unread, router.routeInformationProvider.value.uri.path),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, User user, int unread, String path) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const SebaLogo(size: 36),
                  const SizedBox(width: 12),
                  Text('Seba', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (user.isAdmin)
                    Chip(
                      label: const Text('Admin'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: scheme.primaryContainer,
                      side: BorderSide.none,
                      labelStyle: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        user.initials,
                        style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  for (final item in navItemsFor(user))
                    _SidebarTile(
                      icon: _selected(item, path) ? item.selectedIcon : item.icon,
                      label: item.label,
                      selected: _selected(item, path),
                      onTap: () => _go(context, item.location),
                    ),
                  _SidebarTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    selected: path == '/notifications',
                    trailing: unread > 0 ? Badge(label: Text(unread > 99 ? '99+' : '$unread')) : null,
                    onTap: () => _go(context, '/notifications', push: true),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appearance', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  const Center(child: ThemeModeSelector(compact: true)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: _SidebarTile(
                icon: Icons.logout,
                label: 'Sign out',
                color: scheme.error,
                onTap: () async {
                  if (inDrawer) Navigator.of(context).pop();
                  await confirmSignOut(context, ref);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? (selected ? scheme.onPrimaryContainer : scheme.onSurface);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: fg, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: fg, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, fontSize: 15),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
