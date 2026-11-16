import '../../../core/network/api_client.dart';
import '../domain/service.dart';
import '../domain/service_filters.dart';

/// Reads the service catalog from GET /services.
class ServiceRepository {
  ServiceRepository(this._api);

  final ApiClient _api;

  Future<ServicePage> list({
    ServiceFilters filters = const ServiceFilters(),
    int page = 1,
    int limit = 12,
    bool featuredOnly = false,
  }) async {
    final res = await _api.get('/services', query: {
      ...filters.toQuery(),
      if (featuredOnly) 'featured': 'true',
      'page': page,
      'limit': limit,
    });
    final meta = res.meta ?? const {};
    return ServicePage(
      items: [for (final s in res.data as List) Service.fromJson(s as Map<String, dynamic>)],
      page: (meta['page'] as num?)?.toInt() ?? page,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<ServiceCategory>> categories() async {
    final res = await _api.get('/services/categories');
    return [for (final c in res.data as List) ServiceCategory.fromJson(c as Map<String, dynamic>)];
  }

  Future<Service> detail(String id) async {
    final res = await _api.get('/services/$id');
    return Service.fromJson(res.data as Map<String, dynamic>);
  }
}
