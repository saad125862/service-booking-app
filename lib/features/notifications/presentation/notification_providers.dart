import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepository(ref.watch(apiClientProvider)));

/// The signed-in user's notifications, newest first.
final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) => ref.read(notificationRepositoryProvider).list(),
);

/// Number of unread notifications for the bell badge. Polls the server while the user is
/// signed in (push notifications would need Firebase; polling keeps this dependency-free).
class UnreadCount extends Notifier<int> {
  static const pollInterval = Duration(seconds: 30);

  @override
  int build() {
    final user = ref.watch(authProvider).value;
    if (user == null) return 0;

    final timer = Timer.periodic(pollInterval, (_) => refresh());
    ref.onDispose(timer.cancel);
    Future.microtask(refresh);
    return 0;
  }

  Future<void> refresh() async {
    try {
      final count = await ref.read(notificationRepositoryProvider).unreadCount();
      if (ref.mounted) state = count;
    } catch (_) {
      // Keep the last known count; the bell is a convenience.
    }
  }

  void set(int count) => state = count < 0 ? 0 : count;
}

final unreadCountProvider = NotifierProvider<UnreadCount, int>(UnreadCount.new);
