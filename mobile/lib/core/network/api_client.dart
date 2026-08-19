import 'dart:io';
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
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 15);

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
            debugPrint('[API REQUEST] ${options.method} ${options.uri}');
            final loggedHeaders = Map<String, dynamic>.from(options.headers);
            if (loggedHeaders.containsKey('Authorization')) {
              loggedHeaders['Authorization'] = 'Bearer [HIDDEN]';
            }
            debugPrint('[API] Headers: $loggedHeaders');
            if (options.data != null) {
              if (options.path.contains('/auth/')) {
                debugPrint('[API] Body: [AUTH DATA HIDDEN]');
              } else {
                debugPrint('[API] Body: ${options.data}');
              }
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('[API RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (kDebugMode) {
            debugPrint('[API ERROR] ${e.type.name} ${e.requestOptions.uri}');
            debugPrint('[API ERROR MSG] ${e.response?.statusCode} ${e.message}');
          }

          // Automatic cold-start retry for 502/503/504 or network timeout (1 retry max)
          final statusCode = e.response?.statusCode;
          final isColdStartError = statusCode == 502 ||
              statusCode == 503 ||
              statusCode == 504 ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout;

          final retryCount = (e.requestOptions.extra['retry_count'] as int? ?? 0);
          final isRetryableMethod = e.requestOptions.method == 'GET' ||
              e.requestOptions.path.contains('/auth/') ||
              e.requestOptions.path.contains('health');

          if (isColdStartError && isRetryableMethod && retryCount < 1) {
            const backoffDelay = Duration(seconds: 2);
            if (kDebugMode) {
              debugPrint('[API] Retrying request (1/1) after 2s due to cold start / timeout...');
            }
            await Future.delayed(backoffDelay);
            e.requestOptions.extra['retry_count'] = 1;
            try {
              final response = await _dio.fetch(e.requestOptions);
              return handler.resolve(response);
            } catch (_) {}
          }

          // Refresh Token handling for 401 Unauthorized
          if (statusCode == 401 && !e.requestOptions.path.contains('/auth/')) {
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

  /// Checks connectivity to the backend health endpoint.
  /// Retries up to [maxRetries] times to allow Render cold starts.
  Future<bool> checkHealth({
    int maxRetries = 5,
    Duration retryDelay = const Duration(seconds: 3),
  }) async {
    final rootHost = AppConfig.baseUrl.replaceAll('/api/v1', '');
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          debugPrint('[HEALTH] Checking health (attempt $attempt/$maxRetries)...');
        }

        // Try direct /health at root host
        final response = await Dio().get(
          '$rootHost/health',
          options: Options(
            headers: {'Cache-Control': 'no-cache'},
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

        if (response.statusCode == 200) {
          if (kDebugMode) {
            debugPrint('[HEALTH] Backend is UP and responding!');
          }
          return true;
        }
      } on DioException catch (e) {
        if (kDebugMode) {
          debugPrint('[HEALTH] Health check attempt $attempt failed: ${e.response?.statusCode ?? e.type.name}');
        }
        // Try fallback to /api/v1/health
        try {
          final altResp = await _dio.get(
            'health',
            options: Options(
              sendTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );
          if (altResp.statusCode == 200) {
            return true;
          }
        } catch (_) {}
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[HEALTH] Health check error: $e');
        }
      }

      if (attempt < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }
    return false;
  }

  /// Helper to extract clean human-readable backend error messages.
  static String extractErrorMessage(
    dynamic error, {
    String defaultMsg = 'An error occurred while connecting to server.',
  }) {
    if (error is DioException) {
      if (error.response?.data != null) {
        final data = error.response?.data;
        if (data is Map) {
          if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
            return data['message'].toString();
          }
          if (data['error'] != null && data['error'].toString().trim().isNotEmpty) {
            return data['error'].toString();
          }
          if (data['details'] != null && data['details'].toString().trim().isNotEmpty) {
            return data['details'].toString();
          }
        } else if (data is String && data.trim().isNotEmpty && !data.contains('<html>')) {
          return data;
        }
      }

      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        switch (statusCode) {
          case 400:
            return 'Invalid request details provided.';
          case 401:
            return 'Invalid email or password.';
          case 403:
            return 'Access denied.';
          case 404:
            return 'Requested service or user not found.';
          case 409:
            return 'Email is already registered. Please login.';
          case 422:
            return 'Validation error. Please check your inputs.';
          case 500:
            return 'Server internal error. Please try again.';
          case 502:
          case 503:
          case 504:
            return 'Server is currently starting up. Please try again in a moment.';
          default:
            return 'Server returned error ($statusCode).';
        }
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Server connection timed out. Render backend may be waking up.';
      }

      if (error.type == DioExceptionType.connectionError || error.error is SocketException) {
        return 'Unable to connect to EcoMargin server. Please check your internet connection.';
      }

      return error.message ?? defaultMsg;
    }

    return error?.toString() ?? defaultMsg;
  }

  Dio get dio => _dio;
}
