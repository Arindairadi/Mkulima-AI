import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../config/env/env_config.dart';
import '../errors/exceptions.dart';

/// Thin wrapper around [Dio], configured once and injected everywhere via
/// Riverpod, so every feature module talks to the backend the same way:
/// same base URL, same timeouts, same auth header, same error mapping.
class ApiClient {
  final Dio dio;
  final Future<String?> Function() getAuthToken;

  ApiClient({required this.getAuthToken}) : dio = Dio() {
    dio.options
      ..baseUrl = EnvConfig.apiBaseUrl
      ..connectTimeout = EnvConfig.connectTimeout
      ..receiveTimeout = EnvConfig.receiveTimeout
      ..headers = {'Content-Type': 'application/json'};

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(_mapDioError(error));
        },
      ),
    );

    if (EnvConfig.enableLogging) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          error: true,
          compact: true,
        ),
      );
    }
  }

  DioException _mapDioError(DioException error) {
    // Normalize raw Dio/network errors into our own exception types so
    // repositories can catch ServerException/NetworkException regardless
    // of the transport-layer error shape.
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return error.copyWith(error: const NetworkException());
    }
    if (error.response != null) {
      return error.copyWith(
        error: ServerException(
          error.response?.data?['message']?.toString() ?? 'Server error',
          error.response?.statusCode,
        ),
      );
    }
    return error;
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) {
    return dio.delete<T>(path, data: data);
  }

  /// Multipart POST — used by disease detection to upload a photo alongside
  /// form fields (e.g. crop name) in a single request.
  Future<Response<T>> postMultipart<T>(String path, {required FormData formData}) {
    return dio.post<T>(path, data: formData);
  }
}
