import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/app_notification.dart';
import 'notification_providers.dart';

/// Where a notification leads when tapped.
String? routeForNotification(AppNotification n, {required bool isAdmin}) {
  if (n.appointmentId != null) return isAdmin ? '/admin/bookings/${n.appointmentId}' : '/booking/${n.appointmentId}';
  if (n.discountRequestId != null) return isAdmin ? '/admin/discounts' : '/assistant';
  return null;
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, AppNotification n) async {
    final isAdmin = ref.read(authProvider).value?.isAdmin ?? false;
    final route = routeForNotification(n, isAdmin: isAdmin);
    if (!n.isRead) {
      try {
        await ref.read(notificationRepositoryProvider).markRead(n.id);
        ref.invalidate(notificationsProvider);
        ref.read(unreadCountProvider.notifier).refresh();
      } catch (_) {}
    }
    if (route != null && context.mounted) context.push(route);
  }

  Future<void> _markAll(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationsProvider);
      ref.read(unreadCountProvider.notifier).set(0);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasUnread = notifications.value?.any((n) => !n.isRead) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/')),
        actions: [
          if (hasUnread)
            TextButton.icon(
              onPressed: () => _markAll(context, ref),
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error is ApiException ? error.message : 'Please try again.',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyView(
              icon: Icons.notifications_none,
              title: 'No notifications yet',
              message: 'Booking updates, payment confirmations and discount answers will show up here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.read(unreadCountProvider.notifier).refresh();
              try {
                await ref.read(notificationsProvider.future);
              } catch (_) {}
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return ListTile(
                      onTap: () => _open(context, ref, n),
                      leading: CircleAvatar(
                        backgroundColor: n.isRead ? scheme.surfaceContainerHighest : scheme.primaryContainer,
                        child: Icon(n.icon, color: n.isRead ? scheme.onSurfaceVariant : scheme.onPrimaryContainer),
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w800),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('${n.body}\n${Formatters.timeAgo(n.createdAt)}'),
                      ),
                      isThreeLine: true,
                      trailing: n.isRead
                          ? null
                          : Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                            ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
