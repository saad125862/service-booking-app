import 'package:seba_app/features/notifications/presentation/notification_providers.dart';

/// Unread counter that never polls the network in tests.
class FixedUnread extends UnreadCount {
  FixedUnread([this.count = 0]);

  final int count;

  @override
  int build() => count;

  @override
  Future<void> refresh() async {}
}
