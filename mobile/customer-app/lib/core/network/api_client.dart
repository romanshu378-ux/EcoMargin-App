import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';
import '../config/app_config.dart';

class ApiClient {
  final Dio _dio;
  final StorageService _storageService;

  String _generateRequestId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  ApiClient(this._storageService) : _dio = Dio() {
    _dio.options.baseUrl = AppConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 20);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 20);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          var path = options.path;
          if (path.startsWith('/') && !path.startsWith('http')) {
            options.path = path.substring(1);
          }
          if (!options.baseUrl.endsWith('/')) {
            options.baseUrl = '${options.baseUrl}/';
          }

          options.headers['X-Request-ID'] = _generateRequestId();

          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          if (kDebugMode) {
            debugPrint('[API] --> ${options.method} ${options.uri}');
            final loggedHeaders = Map<String, dynamic>.from(options.headers);
            if (loggedHeaders.containsKey('Authorization')) {
              loggedHeaders['Authorization'] = 'Bearer [HIDDEN]';
            }
            debugPrint('[API] Headers: $loggedHeaders');
            if (options.data != null) {
              debugPrint('[API] Body: ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('[API] <-- ${response.statusCode} ${response.requestOptions.uri}');
            debugPrint('[API] Response data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (kDebugMode) {
            debugPrint('[API] ERR ${e.type.name} ${e.requestOptions.uri}');
            debugPrint('[API]     ${e.response?.statusCode} ${e.message}');
            if (e.response?.data != null) {
              debugPrint('[API] Response data: ${e.response?.data}');
            }
          }

          if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('/auth/')) {
            final refreshToken = await _storageService.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                final refreshDio = Dio();
                refreshDio.options.baseUrl = AppConfig.baseUrl;
                refreshDio.options.headers['Content-Type'] = 'application/json';
                final refreshResponse = await refreshDio.post(
                  '/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['accessToken'];
                  final newRefreshToken = refreshResponse.data['refreshToken'];

                  await _storageService.saveToken(newAccessToken);
                  await _storageService.saveRefreshToken(newRefreshToken);

                  e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  
                  final retryResponse = await _dio.fetch(e.requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (refreshErr) {
                if (kDebugMode) {
                  debugPrint('[API] Token refresh failed: $refreshErr');
                }
                await _storageService.clearAllTokens();
              }
            } else {
               await _storageService.clearAllTokens();
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
