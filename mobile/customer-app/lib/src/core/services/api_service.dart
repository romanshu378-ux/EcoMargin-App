import 'dart:convert';
import 'package:dio/dio.dart';

/// Legacy HTTP service — migrated to use Dio and the production Render backend.
/// All new code should use ApiClient (Dio) via the Riverpod provider chain.
/// This file is kept for compatibility only.
class ApiService {
  /// Production backend URL — single source of truth.
  static const String baseUrl = 'https://eco-margin.onrender.com/api/v1';

  static String? authToken;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static Future<Response> get(String endpoint) async {
    return await _dio.get(endpoint, options: Options(headers: _headers));
  }

  static Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    return await _dio.post(
      endpoint,
      data: jsonEncode(data),
      options: Options(headers: _headers),
    );
  }
}
