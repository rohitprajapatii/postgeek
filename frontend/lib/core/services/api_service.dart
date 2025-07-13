import 'package:dio/dio.dart';

class ApiService {
  late final Dio _dio;
  String? _baseUrl;

  ApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  void setBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  String? get baseUrl => _baseUrl;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    _checkBaseUrl();

    // Debug logging
    print('[ApiService] GET request to: $path');
    print('[ApiService] Base URL: $_baseUrl');
    if (queryParameters != null) {
      print('[ApiService] Query parameters: $queryParameters');
      print('[ApiService] Query parameter types:');
      queryParameters.forEach((key, value) {
        print('  $key: $value (${value.runtimeType})');
      });
    }

    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      print('[ApiService] ✅ Response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('[ApiService] ❌ Error in GET request: $e');
      print('[ApiService] ❌ Error type: ${e.runtimeType}');
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    _checkBaseUrl();
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    _checkBaseUrl();
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    _checkBaseUrl();
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  void _checkBaseUrl() {
    if (_baseUrl == null) {
      throw Exception('Base URL is not set. Call setBaseUrl() first.');
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      print('[ApiService] DioException details:');
      print('  Type: ${error.type}');
      print('  Status code: ${error.response?.statusCode}');
      print('  Response data: ${error.response?.data}');
      print('  Response data type: ${error.response?.data?.runtimeType}');

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception('Connection timeout. Please try again.');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final data = error.response?.data;
          String message = 'Unknown error occurred';

          try {
            if (data is Map && data.containsKey('message')) {
              final messageValue = data['message'];
              if (messageValue is String) {
                message = messageValue;
              } else if (messageValue is List && messageValue.isNotEmpty) {
                message = messageValue.first.toString();
              } else {
                message = messageValue.toString();
              }
            } else if (data is Map && data.containsKey('error')) {
              final errorValue = data['error'];
              if (errorValue is String) {
                message = errorValue;
              } else if (errorValue is List && errorValue.isNotEmpty) {
                message = errorValue.first.toString();
              } else {
                message = errorValue.toString();
              }
            } else if (data is String) {
              message = data;
            } else {
              message = data.toString();
            }
          } catch (e) {
            print('[ApiService] Error extracting message from response: $e');
            message = 'Error processing server response';
          }

          return Exception('Error $statusCode: $message');
        case DioExceptionType.cancel:
          return Exception('Request was cancelled');
        case DioExceptionType.connectionError:
          return Exception('No internet connection');
        case DioExceptionType.unknown:
        default:
          return Exception('An unexpected error occurred: ${error.message}');
      }
    }
    return Exception('An unexpected error occurred: $error');
  }
}
