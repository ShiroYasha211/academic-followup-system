import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({String? token})
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 25),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

  final Dio _dio;
  String get baseUrl => _dio.options.baseUrl;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      () => _dio.get<Object?>(path, queryParameters: queryParameters),
    );
  }

  Future<Map<String, dynamic>> post(String path, {Object? data}) async {
    return _send(() => _dio.post<Object?>(path, data: data));
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    return _send(() => _dio.put<Object?>(path, data: data));
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    return _send(() => _dio.patch<Object?>(path, data: data));
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    return _send(() => _dio.delete<Object?>(path, data: data));
  }

  Future<List<int>> getBytes(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        throw ApiException(
          (data['message'] ?? 'تعذر تحميل الملف.').toString(),
          statusCode: error.response?.statusCode,
          errors: data['errors'],
        );
      }
      throw ApiException(
        error.type == DioExceptionType.connectionError
            ? 'تعذر الاتصال بالخادم. تحقق من الإنترنت أو رابط السيرفر.'
            : 'حدث خطأ أثناء تحميل الملف.',
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<List<int>> getBytesFromUrl(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } on DioException catch (error) {
      throw ApiException(
        error.type == DioExceptionType.connectionError
            ? 'تعذر الاتصال بالخادم. تحقق من الإنترنت أو رابط السيرفر.'
            : 'حدث خطأ أثناء تحميل الملف.',
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return body;
      }
      throw const ApiException('استجابة غير متوقعة من الخادم.');
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        throw ApiException(
          (data['message'] ?? 'تعذر تنفيذ الطلب.').toString(),
          statusCode: error.response?.statusCode,
          errors: data['errors'],
        );
      }
      throw ApiException(
        error.type == DioExceptionType.connectionError
            ? 'تعذر الاتصال بالخادم. تحقق من الإنترنت أو رابط السيرفر.'
            : 'حدث خطأ أثناء الاتصال بالخادم.',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
