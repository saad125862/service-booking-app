import '../../../core/network/api_client.dart';
import '../domain/chat_message.dart';

/// Talks to POST /ai/chat. The Gemini key lives only on the server.
class AssistantRepository {
  AssistantRepository(this._api);

  final ApiClient _api;

  /// [history] is the recent conversation as `{role: user|assistant, content}`.
  Future<ChatReply> chat(String message, List<Map<String, String>> history) async {
    final res = await _api.post('/ai/chat', data: {'message': message, 'history': history});
    return ChatReply.fromJson(res.data as Map<String, dynamic>);
  }
}
