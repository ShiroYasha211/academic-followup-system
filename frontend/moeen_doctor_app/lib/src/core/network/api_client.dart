import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({String? token, Future<void> Function()? onUnauthorized})
    : _onUnauthorized = onUnauthorized,
      _dio = Dio(
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
  final Future<void> Function()? _onUnauthorized;

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
      if (statusCode == 401 && _onUnauthorized != null) {
        final exception = _sessionExpiredException;
        await _handleUnauthorized(exception);
        throw exception;
      }
      if (statusCode >= 400) {
        throw ApiException(
          'تعذر تحميل الملف. رمز الخطأ $statusCode.',
          statusCode: statusCode,
        );
      }
      return response.data ?? const [];
    } on DioException catch (error) {
      final exception = _exceptionFromDio(error, fallback: 'تعذر تحميل الملف.');
      await _handleUnauthorized(exception);
      throw exception;
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
      final exception = _exceptionFromDio(error, fallback: 'تعذر تنفيذ الطلب.');
      await _handleUnauthorized(exception);
      throw exception;
    }
  }

  Future<void> _handleUnauthorized(ApiException exception) async {
    if (exception.statusCode != 401 || _onUnauthorized == null) return;
    await _onUnauthorized();
  }

  ApiException _exceptionFromDio(
    DioException error, {
    required String fallback,
  }) {
    if (error.response?.statusCode == 401 && _onUnauthorized != null) {
      return _sessionExpiredException;
    }

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

  static const _sessionExpiredException = ApiException(
    'انتهت جلسة تسجيل الدخول أو تم تسجيل الحساب من جهاز آخر. يرجى تسجيل الدخول مجددًا.',
    statusCode: 401,
    code: 'session_expired',
  );
}
