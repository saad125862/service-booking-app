import '../../../core/network/api_client.dart';
import '../domain/discount_request.dart';

/// The signed-in customer's discount requests (created through the AI assistant).
class DiscountRepository {
  DiscountRepository(this._api);

  final ApiClient _api;

  Future<List<DiscountRequest>> mine() async {
    final res = await _api.get('/discount-requests');
    return [for (final r in res.data as List) DiscountRequest.fromJson(r as Map<String, dynamic>)];
  }
}
