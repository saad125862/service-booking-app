import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// The unwrapped `{ success, data, meta }` envelope the API returns.
class ApiResponse {
  const ApiResponse(this.data, [this.meta]);
  final dynamic data;
  final Map<String, dynamic>? meta;
}

/// Thin wrapper around Dio: attaches the JWT, unwraps the response envelope and
/// converts every failure into an [ApiException].
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    required void Function() onUnauthorized,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppConfig.apiBaseUrl
      // Render's free tier can take ~50 s to wake up, so be generous.
      ..connectTimeout = const Duration(seconds: 60)
      ..receiveTimeout = const Duration(seconds: 60)
      ..headers = {'Accept': 'application/json'};

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.read();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthCall = error.requestOptions.path.startsWith('/auth/');
          if (error.response?.statusCode == 401 && !isAuthCall) {
            onUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;

  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<ApiResponse> post(String path, {Object? data}) =>
      _send(() => _dio.post(path, data: data));

  Future<ApiResponse> patch(String path, {Object? data}) =>
      _send(() => _dio.patch(path, data: data));

  Future<ApiResponse> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return ApiResponse(body['data'], body['meta'] as Map<String, dynamic>?);
      }
      return const ApiResponse(null);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
