import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({String? token})
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

  final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _send(
      () => _dio.get<Object?>(path, queryParameters: queryParameters),
    );
  }

  Future<Map<String, dynamic>> post(String path, {Object? data}) {
    return _send(() => _dio.post<Object?>(path, data: data));
  }

  Future<Map<String, dynamic>> put(String path, {Object? data}) {
    return _send(() => _dio.put<Object?>(path, data: data));
  }

  Future<Map<String, dynamic>> patch(String path, {Object? data}) {
    return _send(() => _dio.patch<Object?>(path, data: data));
  }

  Future<Map<String, dynamic>> delete(String path, {Object? data}) {
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
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null,
        ),
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 400) {
        throw ApiException('تعذر تحميل الملف. رمز الخطأ $statusCode.');
      }
      return response.data ?? const [];
    } on DioException catch (error) {
      throw _exceptionFromDio(error, fallback: 'تعذر تحميل الملف.');
    }
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return Map<String, dynamic>.from(body);
      if (body is String && body.trim().isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      throw const ApiException('استجابة غير متوقعة من الخادم.');
    } on DioException catch (error) {
      throw _exceptionFromDio(error, fallback: 'تعذر تنفيذ الطلب.');
    }
  }

  ApiException _exceptionFromDio(
    DioException error, {
    required String fallback,
  }) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        (data['message'] ?? fallback).toString(),
        statusCode: error.response?.statusCode,
        errors: data['errors'],
        code: data['code']?.toString(),
      );
    }
    if (data is Map) {
      return ApiException(
        (data['message'] ?? fallback).toString(),
        statusCode: error.response?.statusCode,
        errors: data['errors'],
        code: data['code']?.toString(),
      );
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return const ApiException(
        'تعذر الاتصال بالخادم. تحقق من الإنترنت أو رابط السيرفر.',
      );
    }
    return ApiException(fallback, statusCode: error.response?.statusCode);
  }
}
