import 'package:dio/dio.dart';

/// A failed API call, with a message that is safe to show to the user.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.details = const {},
  });

  final String message;

  /// Machine-readable code from the API, e.g. `SLOT_UNAVAILABLE`, or `NETWORK`.
  final String? code;
  final int? statusCode;

  /// Field-level validation messages, keyed by field name.
  final Map<String, String> details;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => code == 'NETWORK' || code == 'TIMEOUT';

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message:
              'The server is taking too long to respond. It may be waking up, please try again.',
          code: 'TIMEOUT',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          message: "Can't reach the server. Check your internet connection.",
          code: 'NETWORK',
        );
      default:
        break;
    }

    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      final details = <String, String>{};
      final rawDetails = error['details'];
      if (rawDetails is List) {
        for (final d in rawDetails) {
          if (d is Map && d['field'] != null && d['message'] != null) {
            details.putIfAbsent('${d['field']}', () => '${d['message']}');
          }
        }
      }
      return ApiException(
        message: '${error['message'] ?? 'Something went wrong'}',
        code: error['code'] as String?,
        statusCode: e.response?.statusCode,
        details: details,
      );
    }

    return ApiException(
      message: 'Something went wrong. Please try again.',
      statusCode: e.response?.statusCode,
    );
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
