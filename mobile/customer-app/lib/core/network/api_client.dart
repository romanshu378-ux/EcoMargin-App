import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';

class ApiClient {
  static const String _defaultBaseUrl = 'https://ecomargin-app.onrender.com/api/v1';
  final Dio _dio;
  final StorageService _storageService;

  ApiClient(this._storageService) : _dio = Dio() {
    _dio.options.baseUrl = const String.fromEnvironment('API_URL', defaultValue: _defaultBaseUrl);
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          if (kDebugMode) {
            debugPrint('[LOGIN] API URL: ${options.uri}');
            debugPrint('[LOGIN] Request started');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('[LOGIN] Status: ${response.statusCode}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('[LOGIN] Error Type: ${e.type}');
            debugPrint('[LOGIN] Status: ${e.response?.statusCode}');
            debugPrint('[LOGIN] URL: ${e.requestOptions.uri}');
            if (e.response?.data != null) {
              debugPrint('[LOGIN] Response: ${e.response?.data}');
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

