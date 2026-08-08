import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';

class ApiClient {
  static const String _defaultBaseUrl = 'https://ecomargin-app.onrender.com/api/v1';
  final Dio _dio;
  final StorageService _storageService;

  ApiClient(this._storageService) : _dio = Dio() {
    _dio.options.baseUrl = const String.fromEnvironment('API_URL', defaultValue: _defaultBaseUrl);
    _dio.options.connectTimeout = const Duration(seconds: 8);
    _dio.options.receiveTimeout = const Duration(seconds: 8);
    _dio.options.sendTimeout = const Duration(seconds: 8);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          if (kDebugMode) {
            debugPrint('[API Request] ${options.method} ${options.uri}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('[API Response] ${response.statusCode} ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('[API Error] ${e.type} Status: ${e.response?.statusCode} URI: ${e.requestOptions.uri}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

