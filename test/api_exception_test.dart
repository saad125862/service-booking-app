import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seba_app/core/network/api_exception.dart';

DioException _error(DioExceptionType type, {Response<dynamic>? response}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: response,
    );

void main() {
  test('parses the API error envelope, including field details', () {
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/auth/register'),
      statusCode: 400,
      data: {
        'success': false,
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Validation failed',
          'details': [
            {'field': 'email', 'message': 'Enter a valid email address'},
            {'field': 'password', 'message': 'Password must contain a number'},
          ],
        },
      },
    );
    final e = ApiException.fromDio(_error(DioExceptionType.badResponse, response: response));
    expect(e.code, 'VALIDATION_ERROR');
    expect(e.statusCode, 400);
    expect(e.details['email'], 'Enter a valid email address');
    expect(e.details.length, 2);
  });

  test('maps 401 to isUnauthorized', () {
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/users/me'),
      statusCode: 401,
      data: {
        'success': false,
        'error': {'code': 'UNAUTHORIZED', 'message': 'Authentication required'},
      },
    );
    expect(ApiException.fromDio(_error(DioExceptionType.badResponse, response: response)).isUnauthorized, isTrue);
  });

  test('gives friendly messages for network failures and timeouts', () {
    final offline = ApiException.fromDio(_error(DioExceptionType.connectionError));
    expect(offline.isNetwork, isTrue);
    expect(offline.message, contains('internet'));

    final slow = ApiException.fromDio(_error(DioExceptionType.receiveTimeout));
    expect(slow.code, 'TIMEOUT');
  });

  test('falls back to a generic message for unexpected bodies', () {
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: 500,
      data: '<html>oops</html>',
    );
    final e = ApiException.fromDio(_error(DioExceptionType.badResponse, response: response));
    expect(e.message, isNotEmpty);
    expect(e.statusCode, 500);
  });
}
