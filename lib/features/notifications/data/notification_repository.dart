import '../../../core/network/api_client.dart';
import '../domain/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> list({int limit = 50}) async {
    final res = await _api.get('/notifications', query: {'limit': limit});
    return [for (final n in res.data as List) AppNotification.fromJson(n as Map<String, dynamic>)];
  }

  Future<int> unreadCount() async {
    final res = await _api.get('/notifications/unread-count');
    return ((res.data as Map<String, dynamic>)['unreadCount'] as num).toInt();
  }

  Future<void> markRead(String id) async {
    await _api.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.post('/notifications/read-all');
  }
}
